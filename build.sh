#!/bin/bash
#
# This script uses buildah to compose a container image with a DHCP server
#
CONTAINER_NAME=miniboot
#BASE_IMAGE=registry.access.redhat.com/ubi8/ubi
BASE_IMAGE=fedora:34

MAINTAINER="Mark Lamourine <markllama@gmail.com>"


buildah from --name ${CONTAINER_NAME} ${BASE_IMAGE}
buildah config --label maintainer="${MAINTAINER}" ${CONTAINER_NAME}

MOUNTPOINT=$(buildah mount ${CONTAINER_NAME})

dnf -y --install-root ${MOUNTPOINT} tftp-server

buildah unmount ${CONTAINER_NAME}


