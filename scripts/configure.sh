#!/bin/bash
#
# Generate the required config and content files for DHCP, TFTP and HTTP
# to PXE boot coreos
#

# -------------------------------------------------------------------------------------------
#
# -------------------------------------------------------------------------------------------
function main() {
    echo Compose miniboot config File
    local CFG_FILE=$(mktmp --suffix .yaml /tmp/miniboot-XXXXXX)
    cat config.yaml <$(bash scripts/net_yaml.sh br-data) > ${CFG_FILE}

    mkdir -p data
    jinja2 templates/dhcpd.conf.j2 ${CFG_FILE} > data/dhcpd.conf


    jinja2 templates/thttpd.conf.j2 ${CFG_FILE} > data/thttpd.conf

    rm ${CFG_FILE}
}

############################################################################################
main *
