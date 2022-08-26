#!/bin/bash

QUERY=$1

case "${QUERY}" in
    coreos)
        echo "- Download CoreOS Images"
        cat <<EOF
Run this command to download the CoreOS images to the local host:

  mkdir -p ~coreos
  ( cd ~coreos ;
    podman run --privileged --pull=always --rm -v .:/data -w /data \\
        quay.io/coreos/coreos-installer:release download -f pxe )

EOF
        ;;
    config*)
        echo "- Configure"
        cat <<EOF
Edit and fill the sample YAML confuguration file:

  https://github.com/markllama/miniboot/blob/main/config.yaml.sample

EOF
        ;;
    run)
        echo "- Run Miniboot"
        cat <<EOF
  podman run -d --rm --privileged --name miniboot --net=host \\
	  --env INTERFACE=$(INTERFACE) \\
	  --volume $(shell pwd)/config.yaml:/opt/config.yaml \\
	  --volume $(shell pwd)/coreos:/var/www/lighttpd/coreos \\
    quay.io/markllama/miniboot
EOF
        ;;
    *)
        echo '- Info Options:
    help coreos
    help config
    help run'
        ;;
esac
