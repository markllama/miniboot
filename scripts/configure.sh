#!/bin/bash
#
# Generate the required config and content files for DHCP, TFTP and HTTP
# to PXE boot coreos
#

# -------------------------------------------------------------------------------------------
#
# -------------------------------------------------------------------------------------------
function main() {
    echo "Generating the configuration files"

    echo "Generate network configuration"

}

# ------------------------------------------------------------------------------------------
#
# ------------------------------------------------------------------------------------------
function generate_dhcpd_config() {
    # DHCP config required variables
    # network:
    #   addr:
    #
    #   base:
    #   mask:
    #   gateway:
    #
    # dns:
    #   domain:
    #   nameserver:
    #
    # clients:
    #   - mac:
    #     addr:
    #   ...
    echo Generating DHCP server configuration

    echo dhcpd.conf
}

function generate_tftp_files() {
    echo Generating TFTP files

    boot.ipxe
    
}

function generate_http_files() {
    echo Generating HTTP files

    echo thttpd.conf

    
}

############################################################################################
main *
