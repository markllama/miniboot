#!make

IMAGE_REPO=quay.io
REPO_USER=markllama
IMAGE_NAME=miniboot
BUILD_CONTAINER_NAME=miniboot-build
INTERFACE=br-prov

$(IMAGE_NAME)-oci.tgz: build
	podman save --format oci-archive ${IMAGE_NAME} --output $(IMAGE_NAME)-oci.tgz

build: ipxe/src/bin/undionly.kpxe ipxe.efi
	buildah unshare ./build.sh $(BUILD_CONTAINER_NAME) $(IMAGE_NAME)

clean:
	-rm miniboot.tgz
	-buildah delete $(BUILD_CONTAINER_NAME)
	-podman rmi ${IMAGE_NAME}

realclean: clean
	rm -rf data/coreos
	rm ipxe.efi
	cd ipxe/src ; make clean

cli:
	+podman run -it --rm --privileged --name miniboot --net=host \
	  --volume $(shell pwd)/data:/opt \
	  --entrypoint=/bin/bash \
	  ${IMAGE_NAME}

run:
	+podman run -d --rm --privileged --name miniboot --net=host \
	  --volume $(shell pwd)/data:/opt \
	  $(IMAGE_REPO)/$(REPO_USER)/${IMAGE_NAME}

stop:
	-podman stop miniboot
	-podman rm miniboot

tag:
	podman tag ${IMAGE_NAME} ${IMAGE_REPO}/${REPO_USER}/${IMAGE_NAME}

push:
	podman push $(IMAGE_REPO)/$(REPO_USER)/${IMAGE_NAME}

ipxe/src/bin/undionly.kpxe:
	mkdir -p bin
	cd ipxe/src ; make bin/undionly.kpxe

ipxe.efi:
	curl -O http://boot.ipxe.org/ipxe.efi

data/www/coreos:
	mkdir -p data/www/coreos
	cd data/www/coreos ; \
	podman run --privileged --pull=always --rm -v .:/data -w /data \
	  quay.io/coreos/coreos-installer:release download -f pxe ; \
	ln -s fedora-coreos-*-live-kernel-x86_64 kernel ; \
	ln -s fedora-coreos-*-live-initramfs.x86_64.img initrd.img ; \
	ln -s fedora-coreos-*-live-rootfs.x86_64.img rootfs.img

ports:
	firewall-cmd --add-service dhcp
	firewall-cmd --add-service tftp
	firewall-cmd --add-service http

