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

buildah from --name ${CONTAINER_NAME} ${BASE_IMAGE}
buildah config --label maintainer="${MAINTAINER}" ${CONTAINER_NAME}

buildah run ${CONTAINER_NAME} ${DNF} -y install ${RPMS[@]}

# Set up PXE boot in TFTP server
buildah run ${CONTAINER_NAME} ${DNF} -y install syslinux-tftpboot
for PXE_BIN in ${PXE_BINARIES[@]} ; do
    buildah run ${CONTAINER_NAME} cp /tftpboot/${PXE_BIN} /var/lib/tftpboot
done

# Try ipxe instead
buildah add ${CONTAINER_NAME} ipxe/src/bin/undionly.kpxe /var/lib/tftpboot/undionly.kpxe
buildah run ${CONTAINER_NAME} ${DNF} -y remove syslinux-tftpboot

buildah run ${CONTAINER_NAME} ${DNF} clean all

buildah run ${CONTAINER_NAME} systemctl enable ${SERVICES[@]}

buildah config --volume /var/www/thttpd ${CONTAINER_NAME}
buildah config --volume /var/lib/tftpboot/pxelinux.cfg ${CONTAINER_NAME}

buildah config --cmd '["/usr/sbin/init"]' ${CONTAINER_NAME} 

buildah commit ${CONTAINER_NAME} ${IMAGE_NAME}

buildah unmount ${CONTAINER_NAME}
