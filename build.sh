#!/bin/bash
#
# This script uses buildah to compose a container image with a DHCP server
#
#set -x

CONTAINER_NAME=miniboot
BASE_IMAGE=registry.access.redhat.com/ubi8/ubi

MAINTAINER="Mark Lamourine <markllama@gmail.com>"

REPO_RPMS=https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
RPMS=(iproute dhcp-server tftp-server lighttpd python3-pip python3-jinja2 python3-pyyaml tcpdump)
SERVICES=(dhcpd tftp-server lighttpd)
MOUNTPOINTS=(/etc/dhcpd/dhcpd.conf /etc/lighttpd/lighttpd.conf)

buildah from --name ${CONTAINER_NAME} ${BASE_IMAGE}
buildah config --label maintainer="${MAINTAINER}" ${CONTAINER_NAME}

# Configuration files needed:
# /etc/dhcp/dhcpd.conf - assign IP address, provide next-server and filename
# /var/www/lighttpd/coreos/ipxe.conf - 
# /var/www/lighttpd/coreos/config.ign - provide host configuration

buildah config --volume /var/www/lighttpd ${CONTAINER_NAME}

declare -a PORTS=(68/tcp 68/udp 69/tcp 69/udp 80/tcp)
for PORT in ${PORTS[@]} ; do
    buildah config --port ${PORT} ${CONTAINER_NAME}
done

buildah run ${CONTAINER_NAME} dnf -y install ${REPO_RPMS}

for RPM in ${RPMS[@]} ; do
    buildah run ${CONTAINER_NAME} dnf -y install ${RPM}
done

buildah run ${CONTAINER_NAME} pip3 install jinja2-cli

buildah copy ${CONTAINER_NAME} bin/undionly.kpxe /var/lib/tftpboot

buildah run ${CONTAINER_NAME} mkdir -p /var/lib/tftpboot/coreos

buildah run ${CONTAINER_NAME} systemctl enable dhcpd
buildah run ${CONTAINER_NAME} systemctl enable tftp
buildah run ${CONTAINER_NAME} systemctl enable lighttpd

buildah run ${CONTAINER_NAME} dnf clean all

##
## Create config file locations or accept inputs to start
##
buildah copy ${CONTAINER_NAME} templates /opt/templates
buildah run ${CONTAINER_NAME} mkdir /opt/config
buildah config --volume /opt/config ${CONTAINER_NAME}

# dhcpd.conf
# /var/lib/tftpboot

buildah copy ${CONTAINER_NAME} startup.sh /opt/startup.sh
buildah run ${CONTAINER_NAME} chmod 755 /opt/startup.sh
buildah config --cmd /opt/startup.sh ${CONTAINER_NAME}

buildah commit ${CONTAINER_NAME} miniboot

#buildah unmount ${CONTAINER_NAME}


