#!make

IMAGE_NAME=quay.io/markllama/miniboot
CONTAINER_NAME=miniboot-build

build:
	buildah unshare ./build.sh $(CONTAINER_NAME) $(IMAGE_NAME)

clean:
	-buildah delete $(CONTAINER_NAME)
	-podman rmi ${IMAGE_NAME}

clean_all: clean
	rm -rf coreos

cli:
	+podman run -it --rm --privileged --name miniboot --net=host \
	  --volume $(shell pwd)/config.yaml:/opt/config.yaml \
	  --volume $(shell pwd)/coreos:/var/www/lighttpd/coreos \
	  --entrypoint=/bin/bash \
	  ${IMAGE_NAME}

run:
	+podman run -d --rm --privileged --name miniboot --net=host \
	  --env INTERFACE=br-prov \
	  --volume $(shell pwd)/config.yaml:/opt/config.yaml \
	  --volume $(shell pwd)/coreos:/var/www/lighttpd/coreos \
	  ${IMAGE_NAME}

stop:
	-podman stop miniboot
	-podman rm miniboot

push:
	podman push ${IMAGE_NAME}

coreos:
	mkdir -p coreos
	cd coreos ; \
	podman run --privileged --pull=always --rm -v .:/data -w /data \
	  quay.io/coreos/coreos-installer:release download -f pxe

ports:
	firewall-cmd --add-service dhcp
	firewall-cmd --add-service tftp
	firewall-cmd --add-service http

