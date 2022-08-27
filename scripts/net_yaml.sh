#!/bin/bash
#
# Gather the network information from an interface
#
IFACE=$1

function main() {
    local iface=$1

    eval "$(netspecs $1)"
    GATEWAY=$(ip route | grep default | cut -d' ' -f3)
    DOMAIN=$(grep '^search ' /etc/resolv.conf | cut -d' ' -f2)
    NAMESERVER=$(grep nameserver /etc/resolv.conf | head -1 | cut -d' ' -f2)

    cat <<EOF
network:
  interface: ${iface}
  base: ${NETWORK}
  mask: ${NETMASK}
  addr: ${IPADDR}
  gateway: ${GATEWAY}

dns:
  domain: ${DOMAIN}
  nameserver: ${NAMESERVER}
EOF
}

function netspecs() {
    local iface=$1
    
    local ipcidr=$(ip --brief a show dev ${iface} | awk '{print $3}')
    local ip=$(echo $ipcidr | cut -d/ -f1)
    local prefix=$(echo $ipcidr | cut -d/ -f2)
    echo IPADDR=$ip
    ipcalc --network --netmask $ipcidr
}

main $*
