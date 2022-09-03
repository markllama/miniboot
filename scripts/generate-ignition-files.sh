#!/bin/bash

: ${CONFIG_FILE=config_full.yaml}
: ${BUTANE_TEMPLATE=templates/config.bu.j2}
: ${FCOS_DIR=data/www/fcos}


function main() {

    local NODE_INDEX
    
    mkdir -p ${FCOS_DIR}
    for NODE_INDEX in $(seq_nodes) ; do
        local NODE_NAME=$(node_hostname ${NODE_INDEX})
        generate_ignition ${NODE_INDEX}  ${FCOS_DIR}/${NODE_NAME}.ign
        generate_custom_initrd ${NODE_NAME} data/www/fcos data/www/coreos
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

function transform_butane() {
    local NODE_NUMBER=$1

    jinja2 ${BUTANE_TEMPLATE} ${CONFIG_FILE} -D node_number=${NODE_NUMBER} 
}

function transform_nmconnection() {
    local NODE_NUMBER=$1
    jinja2 ${NMINTERFACE_TEMPLATE} ${CONFIG_FILE} -D node_number=${NODE_NUMBER}
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

function initrd_image() {
    local IMAGE_DIR=$1
    ls ${IMAGE_DIR}/fedora-coreos-*-live-initramfs.x86_64.img | sort | tail -1
}

function generate_custom_initrd() {
    local NODE_NAME=$1
    local IGNITION_DIR=$2
    local IMAGE_DIR=$3

    local IMAGE_FILE=${IMAGE_DIR}/${NODE_NAME}-initrd.img
    [ -f ${IMAGE_FILE}] && rm -f ${IMAGE_FILE}
    coreos-installer pxe customize \
      --dest-device /dev/sda \
      --dest-ignition ${IGNITION_DIR}/${NODE_NAME}.ign \
      --network-keyfile static-ip.nmconnection \
      -o ${IMAGE_FILE} \
      $(initrd_image ${IMAGE_DIR})
    chmod a+r ${IMAGE_FILE}
}

main $*
