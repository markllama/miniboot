#!/bin/bash

: ${CONFIG_FILE=config_full.yaml}
: ${IPXE_TEMPLATE=templates/boot.ipxe.j2}
: ${BUTANE_TEMPLATE=templates/config.bu.j2}
: ${NMCONNECTION_TEMPLATE=templates/device.nmconnection.j2}
: ${IPXE_DIR=data/www/ipxe}
: ${FCOS_DIR=data/fcos}

function main() {

    local NODE_INDEX
    
    mkdir -p ${IPXE_DIR}
    mkdir -p ${FCOS_DIR}
    for NODE_INDEX in $(seq_nodes) ; do
        local NODE_NAME=$(node_hostname ${NODE_INDEX})
        generate_ipxe ${NODE_INDEX} ${IPXE_DIR}/${NODE_NAME}.ipxe
        generate_ignition ${NODE_INDEX}  ${FCOS_DIR}/${NODE_NAME}.ign
        generate_nmconnection ${NODE_INDEX} ${FCOS_DIR}/${NODE_NAME}.nmconnection
        generate_custom_initrd ${NODE_NAME} $(node_architecture ${NODE_INDEX}) ${FCOS_DIR} data/www/coreos
    done
}

function num_nodes() {
    yq  '.nodes | length' < ${CONFIG_FILE}
}

function seq_nodes() {
    seq 0 $(($(num_nodes) - 1))
}

function node_hostname() {
    local NODE_NUMBER=$1
    yq --raw-output ".nodes[${NODE_NUMBER}].hostname" < ${CONFIG_FILE}
}

function node_architecture() {
    local NODE_NUMBER=$1
    yq --raw-output ".nodes[${NODE_NUMBER}].arch" < ${CONFIG_FILE}
}

function transform_ipxe() {
    local NODE_NUMBER=$1
    jinja2 ${IPXE_TEMPLATE} ${CONFIG_FILE} -D node_number=${NODE_NUMBER}
}

function transform_butane() {
    local NODE_NUMBER=$1

    jinja2 ${BUTANE_TEMPLATE} ${CONFIG_FILE} -D node_number=${NODE_NUMBER} 
}

function transform_nmconnection() {
    local NODE_NUMBER=$1
    jinja2 ${NMCONNECTION_TEMPLATE} ${CONFIG_FILE} -D node_number=${NODE_NUMBER}
}

function generate_ipxe() {
    local NODE_INDEX=$1
    local IPXE_FILE=$2
    transform_ipxe ${NODE_INDEX} > ${IPXE_FILE}
}
function generate_ignition() {
    local NODE_INDEX=$1
    local IGNITION_FILE=$2
    BUTANE_FILE=$(mktemp /tmp/fcos-config-XXXX.bu)
    transform_butane ${NODE_INDEX} > ${BUTANE_FILE}
    podman --remote run --interactive --rm \
           --security-opt label=disable \
           --volume ${PWD}:/pwd \
           --workdir /pwd \
           quay.io/coreos/butane:release \
           --pretty --strict \
           <${BUTANE_FILE} >${IGNITION_FILE}
    rm ${BUTANE_FILE}
}

function generate_nmconnection() {
    local NODE_INDEX=$1
    local NMCONNECTION_FILE=$2
    transform_nmconnection ${NODE_INDEX} >${NMCONNECTION_FILE}
}

function initrd_image() {
    local IMAGE_DIR=$1
    local ARCH=$2
    ls ${IMAGE_DIR}/fedora-coreos-*-live-initramfs.${ARCH}.img | sort | tail -1
}

function generate_custom_initrd() {
    local NODE_NAME=$1
    local NODE_ARCH=$2
    local FCOS_DIR=$3
    local IMAGE_DIR=$4

    local IMAGE_FILE=${IMAGE_DIR}/${NODE_NAME}-initrd-${NODE_ARCH}.img
    [ -f ${IMAGE_FILE} ] && rm -f ${IMAGE_FILE}
    coreos-installer pxe customize \
      --dest-device /dev/sda \
      --dest-ignition ${FCOS_DIR}/${NODE_NAME}.ign \
      --network-keyfile ${FCOS_DIR}/${NODE_NAME}.nmconnection \
      -o ${IMAGE_FILE} \
      $(initrd_image ${IMAGE_DIR} ${NODE_ARCH})
    chmod a+r ${IMAGE_FILE}
}

main $*
