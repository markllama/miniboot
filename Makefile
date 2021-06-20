#!make

IMAGE_NAME=quay.io/markllama/miniboot
CONTAINER_NAME=miniboot-build
INTERFACE=br-prov

miniboot-oci.tgz: build
	podman save --format oci-archive ${IMAGE_NAME} --output miniboot-oci.tgz

build: ipxe/src/bin/undionly.kpxe
	buildah unshare ./build.sh $(CONTAINER_NAME) $(IMAGE_NAME)

clean:
	-rm miniboot.tgz
	-buildah delete $(CONTAINER_NAME)
	-podman rmi ${IMAGE_NAME}

realclean: clean
	rm -rf coreos
	cd ipxe/src ; make clean

cli:
	+podman run -it --rm --privileged --name miniboot --net=host \
	  --volume $(shell pwd)/config.yaml:/opt/config.yaml \
	  --volume $(shell pwd)/coreos:/var/www/lighttpd/coreos \
	  --entrypoint=/bin/bash \
	  ${IMAGE_NAME}

run:
	+podman run -d --rm --privileged --name miniboot --net=host \
	  --env INTERFACE=$(INTERFACE) \
	  --volume $(shell pwd)/config.yaml:/opt/config.yaml \
	  --volume $(shell pwd)/coreos:/var/www/lighttpd/coreos \
	  ${IMAGE_NAME}

stop:
	-podman stop miniboot
	-podman rm miniboot

push:
	podman push ${IMAGE_NAME}

ipxe/src/bin/undionly.kpxe:
	mkdir -p bin
	cd ipxe/src ; make bin/undionly.kpxe

coreos:
	mkdir -p coreos
	cd coreos ; \
	podman run --privileged --pull=always --rm -v .:/data -w /data \
	  quay.io/coreos/coreos-installer:release download -f pxe

ports:
	firewall-cmd --add-service dhcp
	firewall-cmd --add-service tftp
	firewall-cmd --add-service http

