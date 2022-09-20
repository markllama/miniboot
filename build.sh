#!/bin/bash
#
# This script uses buildah to compose a container image with a DHCP server
#
MAINTAINER="Mark Lamourine <markllama@gmail.com>"

CONTAINER_NAME=$1
IMAGE_NAME=$2

#BASE_IMAGE=registry.access.redhat.com/ubi8/ubi
BASE_IMAGE=registry.fedoraproject.org/fedora-minimal:36
DNF=microdnf

RPMS=(systemd dhcp-server tftp-server thttpd)
SERVICES=(dhcpd tftp thttpd)
PXE_BINARIES=(ldlinux.c32  lpxelinux.0  memdisk  pxelinux.0)

function main() {
    set_container_metadata
    install_and_configure_systemd_services
    populate_pxelinux_binaries
    populate_ipxe_binaries
    finalize_container_image
}


# A shortcut for commands that run inside the container
function buildah_run() {
    buildah run ${CONTAINER_NAME} $*
}

# This function replaces a file or directory in the container with a link to a 
# location in an imported volume
function replace_with_link() {
    local FILE=$1
    local LINK=$2

    buildah_run rm -rf ${FILE}
    buildah_run ln -s ${LINK} ${FILE}
}

# ==================================================================================
#
# ==================================================================================

function set_container_metadata() {   
    # Set container metadata
    buildah from --name ${CONTAINER_NAME} ${BASE_IMAGE}
    buildah config --label maintainer="${MAINTAINER}" ${CONTAINER_NAME}
    buildah config --volume /data ${CONTAINER_NAME}
}

function install_and_configure_systemd_services() {
    # Install service packages
    buildah_run ${DNF} -y install ${RPMS[@]}

    # dhcpd.conf refers to the server and lease configs by includes
    # - /opt/etc/dhcpd_server.conf
    # - /opt/etc/dhcpd_leases.conf
    buildah add ${CONTAINER_NAME} dhcpd.conf /etc/dhcp/dhcpd.conf
    
    # The remaining input is mounted on /data
    # Replace the stock config files with symlinks to the import directory: /opt
    replace_with_link /etc/thttpd.conf /opt/etc/thttpd.conf
    replace_with_link /var/www/thttpd /opt/www
    
    # Enable services inside the container
    buildah_run systemctl enable ${SERVICES[@]}
    # Start with systemd
    buildah config --cmd '["/usr/sbin/init"]' ${CONTAINER_NAME} 
}

function populate_pxelinux_binaries() {
    # Populate the PXELINUX boot files in the TFTP repository
    buildah_run ${DNF} -y install syslinux-tftpboot
    for PXE_BIN in ${PXE_BINARIES[@]} ; do
        buildah_run cp /tftpboot/${PXE_BIN} /var/lib/tftpboot
    done
    buildah_run ${DNF} -y remove syslinux-tftpboot
    buildah_run ${DNF} clean all
}

function populate_ipxe_binaries() {
    # Place iPXE boot files in the TFTP repository
    buildah add ${CONTAINER_NAME} ipxe/src/bin/undionly.kpxe /var/lib/tftpboot/undionly.kpxe
    buildah add ${CONTAINER_NAME} ipxe.efi /var/lib/tftpboot/ipxe.efi
}

function finalize_container_image() {
    #
    # Finalize the new container image
    #
    buildah commit ${CONTAINER_NAME} ${IMAGE_NAME}
    buildah unmount ${CONTAINER_NAME}
}

# ----------------------------------------------------------------------------------------------
# Execute the main function
main $*
