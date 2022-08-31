#!/bin/bash
#
# This script uses buildah to compose a container image with a DHCP server
#
set -x

CONTAINER_NAME=$1

#BASE_IMAGE=registry.access.redhat.com/ubi8/ubi
BASE_IMAGE=registry.fedoraproject.org/fedora-minimal:36
DNF=microdnf
IMAGE_NAME=$2

MAINTAINER="Mark Lamourine <markllama@gmail.com>"

CURL_OPTS="--location --remote-name --output-dir /tmp"
RPMS=(systemd dhcp-server tftp-server thttpd)
SERVICES=(dhcpd tftp thttpd)

PXE_BINARIES=(ldlinux.c32  lpxelinux.0  memdisk  pxelinux.0)

function buildah_run() {
    buildah run ${CONTAINER_NAME} $*
}

function replace_with_link() {
    local FILE=$1
    local LINK=$2

    buildah run ${CONTAINER_NAME} rm -rf ${FILE}
    buildah run ${CONTAINER_NAME} ln -s ${LINK} ${FILE}
}

# ==================================================================================
#
# ==================================================================================

buildah from --name ${CONTAINER_NAME} ${BASE_IMAGE}
buildah config --label maintainer="${MAINTAINER}" ${CONTAINER_NAME}

buildah_run ${DNF} -y install ${RPMS[@]}

# Set up PXE boot in TFTP server
buildah_run ${DNF} -y install syslinux-tftpboot
for PXE_BIN in ${PXE_BINARIES[@]} ; do
    buildah_run cp /tftpboot/${PXE_BIN} /var/lib/tftpboot
done

# Try ipxe instead
buildah add ${CONTAINER_NAME} ipxe/src/bin/undionly.kpxe /var/lib/tftpboot/undionly.kpxe
buildah add ${CONTAINER_NAME} ipxe.efi /var/lib/tftpboot/ipxe.efi

buildah_run ${DNF} -y remove syslinux-tftpboot

buildah_run ${DNF} clean all

buildah_run systemctl enable ${SERVICES[@]}

buildah config --volume /data ${CONTAINER_NAME}

# All of the input is mounted on /data
# /etc/dhcp/dhcpd.conf -> /data/dhcpd.conf
replace_with_link /etc/dhcp/dhcpd.conf /opt/dhcpd.conf 
replace_with_link /etc/thttpd.conf /opt/thttpd.conf
replace_with_link /var/lib/tftpboot/pxelinux.cfg /opt/pxelinux.cfg 
replace_with_link /var/www/thttpd /opt/www

buildah config --cmd '["/usr/sbin/init"]' ${CONTAINER_NAME} 

buildah commit ${CONTAINER_NAME} ${IMAGE_NAME}

buildah unmount ${CONTAINER_NAME}
