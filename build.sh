#!/bin/bash
#
# This script uses buildah to compose a container image with a DHCP server
#
set -x

CONTAINER_NAME=miniboot
BASE_IMAGE=registry.access.redhat.com/ubi8/ubi
#BASE_IMAGE=fedora:34
COREOS_VERSION=33.20210426.3.0
COREOS_KERNEL=fedora-coreos-${COREOS_VERSION}-live-kernel-x86_64
COREOS_INITRD=fedora-coreos-${COREOS_VERSION}-live-initramfs.x86_64.img
COREOS_ROOTRD=fedora-coreos-${COREOS_VERSION}-live-rootfs.x86_64.img

MAINTAINER="Mark Lamourine <markllama@gmail.com>"

REPO_RPMS=(https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm)
RPMS=(dhcp-server tftp-server syslinux-tftpboot lighttpd)
SERVICES=(dhcpd tftp-server lighttpd)
MOUNTPOINTS=(/etc/dhcpd/dhcpd.conf /etc/lighttpd/lighttpd.conf)


buildah from --name ${CONTAINER_NAME} ${BASE_IMAGE}
buildah config --label maintainer="${MAINTAINER}" ${CONTAINER_NAME}

buildah run ${CONTAINER_NAME} dnf -y install dhcp-server
buildah run ${CONTAINER_NAME} dnf -y install tftp-server
buildah run ${CONTAINER_NAME} dnf -y install syslinux-tftpboot

buildah run ${CONTAINER_NAME} cp /tftpboot/{pxelinux.0,ldlinux.c32} /var/lib/tftpboot
buildah run ${CONTAINER_NAME} mkdir -p /var/lib/tftpboot/pxelinux.cfg
buildah run ${CONTAINER_NAME} dnf -y remove syslinux-tftpboot

buildah run ${CONTAINER_NAME} mkdir -p /var/lib/tftpboot/coreos
buildah copy ${CONTAINER_NAME} ${COREOS_KERNEL} /var/lib/tftpboot/coreos/kernel
buildah copy ${CONTAINER_NAME} ${COREOS_INITRD} /var/lib/tftpboot/coreos/initrd
buildah copy ${CONTAINER_NAME} ${COREOS_ROOTRD} /var/lib/tftpboot/coreos/rootrd

buildah run ${CONTAINER_NAME} dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
buildah run ${CONTAINER_NAME} dnf -y install lighttpd

buildah run ${CONTAINER_NAME} systemctl enable dhcpd
buildah run ${CONTAINER_NAME} systemctl enable tftp-server
buildah run ${CONTAINER_NAME} systemctl enable lighttpd

buildah run ${CONTAINER_NAME} dnf clean all

##
## Create config file locations or accept inputs to start
##
# dhcpd.conf
# /var/lib/tftpboot

buildah commit ${CONTAINER_NAME} miniboot

#buildah unmount ${CONTAINER_NAME}


