#!/bin/bash
#
# Place configuration files for dhcpd, pxelinux and ignition for CoreOS boot
#

# create /etc/dhcp/dhcpd.conf
#  This causes the host to load the IPXE binary
jinja2 /opt/templates/dhcpd.conf.j2 /opt/config/config.yaml > /etc/dhcp/dhcpd.conf


# Finally start systemd
exec /sbin/init
