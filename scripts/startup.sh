#!/bin/bash -x
#
set -x

if [ $# -gt 1 ] ; then
    if [ "$2" == "help" ] ; then
      bash /opt/help.sh "$3"
    else
      echo "only help is supported: $*"
    fi 
    exit 0
fi

# Place configuration files for dhcpd, pxelinux and ignition for CoreOS boot
#
# Make a copy of the provided config
cp /opt/config.yaml /opt/config_full.yaml

# Append the network config from the provided interface
/opt/net_yaml.sh ${INTERFACE} >> /opt/config_full.yaml

ARCH=$(uname -m)
cd /var/www/lighttpd
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


function run_cmd() {
    # Support docker run --init parameter which obsoletes the use of dumb-init,
    # but support dumb-init for those that still use it without --init

    local run
    if [ -x "/dev/init" ]; then
        run="exec /usr/bin/tini"
    else
        run="exec /usr/bin/dumb-init --"
    fi

    echo $run
}

# Finally start systemd
/usr/sbin/init
