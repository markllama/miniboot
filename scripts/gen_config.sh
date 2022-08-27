#!/bin/bash -x
#

# Place configuration files for dhcpd, pxelinux and ignition for CoreOS boot
#
# Make a copy of the provided config
cp /opt/config.yaml /opt/config_full.yaml

# Append the network config from the provided interface
/opt/net_yaml.sh ${INTERFACE} >> /opt/config_full.yaml

ARCH=$(uname -m)
cd /var/www/thttpd
cat <<EOF >> /opt/config_full.yaml
coreos:
  kernel: $(find coreos -name fedora-coreos\*kernel-${ARCH} | head -1)
  initrd: $(find coreos -name fedora-coreos\*initramfs.${ARCH}.img | head -1)
  rootfs: $(find coreos -name fedora-coreos\*rootfs.${ARCH}.img | head -1)
EOF
cd /opt

# create /etc/dhcp/dhcpd.conf
#  This causes the host to load the IPXE binary
jinja2 /opt/templates/dhcpd.conf.j2 /opt/config_full.yaml > /etc/dhcp/dhcpd.conf
jinja2 /opt/templates/boot.ipxe.j2 /opt/config_full.yaml > /var/www/lighttpd/boot.ipxe
jinja2 /opt/templates/config.ign.j2 /opt/config_full.yaml > /var/www/lighttpd/config.ign
