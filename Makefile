#!make

IMAGE_NAME=miniboot
COREOS_VERSION=33.20210426.3.0
COREOS_KERNEL=fedora-coreos-$(COREOS_VERSION)-live-kernel-x86_64
COREOS_INITFS=fedora-coreos-$(COREOS_VERSION)-live-initramfs.x86_64.img
COREOS_ROOTFS=fedora-coreos-$(COREOS_VERSION)-live-rootfs.x86_64.img

build: coreos/$(COREOS_KERNEL) coreos/$(COREOS_INITFS) coreos/$(COREOS_ROOTFS)
	buildah unshare ./build.sh $(IMAGE_NAME)

clean:
	-buildah delete $(IMAGE_NAME)
	-podman rmi ${IMAGE_NAME}

clean_all: clean
	rm -rf coreos

run:
	podman run -it --rm --privileged --name miniboot --net=host localhost/miniboot /bin/bash

stop:
	-podman stop miniboot
	-podman rm miniboot

coreos/$(COREOS_KERNEL):
	mkdir -p coreos
	cd coreos ; \
	podman run --privileged --pull=always --rm -v .:/data -w /data \
	  quay.io/coreos/coreos-installer:release download -f pxe

coreos/$(COREOS_INITFS): coreos/$(COREOS_KERNEL)
coreos/$(COREOS_ROOTFS): coreos/$(COREOS_KERNEL)

