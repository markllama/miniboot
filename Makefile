#!make

IMAGE_NAME=miniboot
#COREOS_VERSION=34.20210427.3.0
COREOS_KERNEL=fedora-coreos-$(COREOS_VERSION)-live-kernel-x86_64
COREOS_INITFS=fedora-coreos-$(COREOS_VERSION)-live-initramfs.x86_64.img
COREOS_ROOTFS=fedora-coreos-$(COREOS_VERSION)-live-rootfs.x86_64.img

build: coreos
	buildah unshare ./build.sh $(IMAGE_NAME)

clean:
	-buildah delete $(IMAGE_NAME)
	-podman rmi ${IMAGE_NAME}

clean_all: clean
	rm -rf coreos

cli:
	podman run -it --rm --privileged --name miniboot --net=host \
	  --volume $(PWD)/test:/opt/config \
	  --volume $(PWD)/coreos:/var/lib/tftpboot/coreos \
	  --entrypoint=/bin/bash \
	  localhost/miniboot

run:
	podman run -d --rm --privileged --name miniboot --net=host \
	  --volume $(PWD)/test:/opt/config \
	  --volume $(PWD)/coreos:/var/lib/tftpboot/coreos \
	  localhost/miniboot

stop:
	-podman stop miniboot
	-podman rm miniboot

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



