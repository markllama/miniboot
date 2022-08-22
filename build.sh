#!/bin/bash
#
# This script uses buildah to compose a container image with a DHCP server
#
set -x

CONTAINER_NAME=$1
#BASE_IMAGE=registry.access.redhat.com/ubi8/ubi
BASE_IMAGE=registry.fedoraproject.org/fedora-minimal:36
IMAGE_NAME=$2

MAINTAINER="Mark Lamourine <markllama@gmail.com>"

RPMS=(thttpd)
SERVICES=(thttpd)

buildah from --name ${CONTAINER_NAME} ${BASE_IMAGE}
buildah config --label maintainer="${MAINTAINER}" ${CONTAINER_NAME}

buildah config --port 8080/tcp ${CONTAINER_NAME}

buildah run ${CONTAINER_NAME} microdnf -y install ${RPMS[@]}

# Try ipxe instead
#buildah add ${CONTAINER_NAME} ipxe/src/bin/undionly.kpxe /var/www/tftpboot/undionly.kpxe

buildah run ${CONTAINER_NAME} microdnf clean all

# Modify thttpd config to come from the command line arguments in /etc/sysconfig/thttpd
buildah run ${CONTAINER_NAME} \
        sed -i -e '/^ExecStart=/s/-C .*$/${THTTPD_OPTS}/' \
        /etc/systemd/system/multi-user.target.wants/thttpd.service

buildah config --volume /var/www/thttpd ${CONTAINER_NAME}

buildah config --cmd '["/sbin/init"]' ${CONTAINER_NAME} 

buildah commit ${CONTAINER_NAME} ${IMAGE_NAME}

buildah unmount ${CONTAINER_NAME}
