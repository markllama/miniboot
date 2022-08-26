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

RPMS=(systemd dhcp-server tftp-server python3-pip python3-pyyaml iproute ipcalc lighttpd ipcalc)
SERVICES=(dhcpd tftp lighttpd)

buildah from --name ${CONTAINER_NAME} ${BASE_IMAGE}
buildah config --label maintainer="${MAINTAINER}" ${CONTAINER_NAME}

buildah config --port 68/tcp,68/udp,69/tcp,69/udp ${CONTAINER_NAME}


buildah run ${CONTAINER_NAME} ${DNF} -y install ${RPMS[@]}
buildah run ${CONTAINER_NAME} ${DNF} -y install lighttpd tcpdump

buildah run ${CONTAINER_NAME} pip3 install jinja2-cli

buildah run ${CONTAINER_NAME} systemctl enable dhcpd
buildah run ${CONTAINER_NAME} systemctl enable tftp
buildah run ${CONTAINER_NAME} systemctl enable lighttpd

# Try ipxe instead
buildah add ${CONTAINER_NAME} ipxe/src/bin/undionly.kpxe /var/lib/tftpboot/undionly.kpxe

buildah run ${CONTAINER_NAME} mkdir /var/www/lighttpd/coreos

buildah run ${CONTAINER_NAME} ${DNF} clean all

buildah copy ${CONTAINER_NAME} templates /opt/templates
buildah run ${CONTAINER_NAME} mkdir /opt/config
buildah config --volume /opt/config ${CONTAINER_NAME}
buildah config --volume /var/www/lighttpd/coreos ${CONTAINER_NAME}

buildah config --env INTERFACE=eno1

buildah copy ${CONTAINER_NAME} startup.sh /opt/startup.sh
buildah run ${CONTAINER_NAME} chmod 755 /opt/startup.sh

buildah copy ${CONTAINER_NAME} help.sh /opt/help.sh
buildah copy ${CONTAINER_NAME} help.sh /opt/help.sh

buildah copy ${CONTAINER_NAME} net_yaml.sh /opt/net_yaml.sh
buildah run ${CONTAINER_NAME} chmod 755 /opt/net_yaml.sh


#buildah config --cmd /opt/startup.sh ${CONTAINER_NAME}
buildah config --entrypoint '["/opt/startup.sh"]' ${CONTAINER_NAME} 

buildah commit ${CONTAINER_NAME} ${IMAGE_NAME}

buildah unmount ${CONTAINER_NAME}
