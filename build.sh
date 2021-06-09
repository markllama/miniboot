#!/bin/bash
#
# This script uses buildah to compose a container image with a DHCP server
#
#set -x

CONTAINER_NAME=$1
BASE_IMAGE=registry.access.redhat.com/ubi8/ubi
IMAGE_NAME=$2

MAINTAINER="Mark Lamourine <markllama@gmail.com>"

REPO_RPMS=https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
RPMS=(dhcp-server tftp-server python3-pip python3-pyyaml)
SERVICES=(dhcpd tftp-server)

buildah from --name ${CONTAINER_NAME} ${BASE_IMAGE}
buildah config --label maintainer="${MAINTAINER}" ${CONTAINER_NAME}

buildah config --port 68/tcp,68/udp,69/tcp,69/udp ${CONTAINER_NAME}

buildah run ${CONTAINER_NAME} dnf -y install ${REPO_RPMS}

for RPM in ${RPMS[@]} ; do
    buildah run ${CONTAINER_NAME} dnf -y install ${RPM}
done

buildah run ${CONTAINER_NAME} pip3 install jinja2-cli

buildah run ${CONTAINER_NAME} systemctl enable dhcpd
buildah run ${CONTAINER_NAME} systemctl enable tftp

buildah run ${CONTAINER_NAME} dnf clean all

buildah copy ${CONTAINER_NAME} templates /opt/templates
buildah run ${CONTAINER_NAME} mkdir /opt/config
buildah config --volume /opt/config ${CONTAINER_NAME}

buildah copy ${CONTAINER_NAME} startup.sh /opt/startup.sh
buildah run ${CONTAINER_NAME} chmod 755 /opt/startup.sh
buildah config --cmd /opt/startup.sh ${CONTAINER_NAME}

buildah commit ${CONTAINER_NAME} ${IMAGE_NAME}

buildah unmount ${CONTAINER_NAME}


