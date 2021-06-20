#!/bin/bash
#
# Place configuration files for dhcpd, pxelinux and ignition for CoreOS boot
#

cp /opt/config/config.yaml /opt/config.yaml
/opt/net_yaml.sh ${INTERFACE} >> /opt/config.yaml

# create /etc/dhcp/dhcpd.conf
#  This causes the host to load the IPXE binary
jinja2 /opt/templates/dhcpd.conf.j2 /opt/config.yaml > /etc/dhcp/dhcpd.conf
#jinja2 /opt/templates/pxelinux.cfg.j2 /opt/config/config.yaml > /var/lib/tftpboot/pxelinux.cfg/default
jinja2 /opt/templates/boot.ipxe.j2 /opt/config.yaml > /var/www/lighttpd/boot.ipxe
#jinja2 /opt/templates/config.ign.j2 /opt/config.yaml > /var/lib/tftpboot/config.ign
jinja2 /opt/templates/config.ign.j2 /opt/config.yaml > /var/www/lighttpd/config.ign


# Finally start systemd
exec /sbin/init
