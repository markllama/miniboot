#!/bin/bash

: ${NODENAME=node1}
: ${ROOT_DEVICE=/dev/sda}
: ${IGNITION_FILE=data/www/${NODENAME}-config.ign}

coreos-installer \
    pxe customize \
    --dest-ignition ${IGNITION_FILE} \
    --dest-device ${ROOT_DEVICE} \
    --dest-karg-append console=ttyS1,115200n8 \
    --dest-karg-delete rhgb \
    --dest-karg-delete quiet \
    --output data/www/coreos/${NODENAME}-initrd.img \
        data/www/coreos/initrd.img   
