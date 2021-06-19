#!make

IMAGE_NAME=quay.io/markllama/miniboot
CONTAINER_NAME=miniboot-build
#COREOS_VERSION=34.20210427.3.0
COREOS_KERNEL=fedora-coreos-$(COREOS_VERSION)-live-kernel-x86_64
COREOS_INITFS=fedora-coreos-$(COREOS_VERSION)-live-initramfs.x86_64.img
COREOS_ROOTFS=fedora-coreos-$(COREOS_VERSION)-live-rootfs.x86_64.img

build:
	buildah unshare ./build.sh $(CONTAINER_NAME) $(IMAGE_NAME)

clean:
	-buildah delete $(CONTAINER_NAME)
	-podman rmi ${IMAGE_NAME}

clean_all: clean
	rm -rf coreos

cli:
	+podman run -it --rm --privileged --name miniboot --net=host \
	  --volume $(shell pwd)/test:/opt/config \
	  --volume $(shell pwd)/coreos:/var/www/lighttpd/coreos \
	  --entrypoint=/bin/bash \
	  ${IMAGE_NAME}

run:
	+podman run -d --rm --privileged --name miniboot --net=host \
	  --volume $(shell pwd)/test:/opt/config \
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
	  quay.io/coreos/coreos-installer:release download -f pxe ; \
	ln -s *kernel-x86_64 kernel ; \
	ln -s *initramfs.x86_64.img initrd ; \
	ln -s *rootfs.x86_64.img rootfs


coreos/$(COREOS_INITFS): coreos/$(COREOS_KERNEL)
coreos/$(COREOS_ROOTFS): coreos/$(COREOS_KERNEL)



