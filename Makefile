#!make

IMAGE_NAME=miniboot
COREOS_VERSION=33.20210426.3.0
COREOS_KERNEL=fedora-coreos-$(COREOS_VERSION)-live-kernel-x86_64
COREOS_RAMDISK=fedora-coreos-$(COREOS_VERSION)-live-initramfs.x86_64.img

build: $(COREOS_KERNEL) $(COREOS_RAMDISK)
	buildah unshare ./build.sh $(IMAGE_NAME)

clean:
	-buildah delete $(IMAGE_NAME)
	-podman rmi ${IMAGE_NAME}

clean_all: clean
	rm fedora-coreos*

run:
	podman run -it --rm --name miniboot localhost/miniboot /bin/bash

$(COREOS_KERNEL):
	podman run --privileged --pull=always --rm -v .:/data -w /data \
	  quay.io/coreos/coreos-installer:release download -f pxe

$(COREOS_RAMDISK): $(COREOS_KERNEL)

