#!/bin/bash
#
# Place configuration files for dhcpd, pxelinux and ignition for CoreOS boot
#

# create /etc/dhcp/dhcpd.conf
jinja2 /opt/templates/dhcpd.conf.j2 /opt/config/config.yaml > /etc/dhcp/dhcpd.conf

# create 


# Finally start systemd
exec /sbin/init
