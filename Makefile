#!make

IMAGE_REPO=quay.io
REPO_USER=markllama
IMAGE_NAME=miniboot
BUILD_CONTAINER_NAME=miniboot-build
INTERFACE=br-prov
#PODMAN="podman --remote"
PODMAN=podman

$(IMAGE_NAME)-oci.tgz: build
	${PODMAN} save --format oci-archive ${IMAGE_NAME} --output $(IMAGE_NAME)-oci.tgz

build: ipxe/src/bin/undionly.kpxe ipxe.efi
	buildah unshare ./build.sh $(BUILD_CONTAINER_NAME) $(IMAGE_NAME)

clean:
	-rm miniboot.tgz
	-buildah delete $(BUILD_CONTAINER_NAME)
	-${PODMAN} rmi ${IMAGE_NAME}

realclean: clean
	rm -rf data/coreos
	rm ipxe.efi
	cd ipxe/src ; make clean

cli:
	+${PODMAN} run -it --rm --privileged --name miniboot --net=host \
	  --volume $(shell pwd)/data:/opt \
	  --entrypoint=/bin/bash \
	  ${IMAGE_NAME}

run:
	+${PODMAN} run -d --rm --privileged --name miniboot --net=host \
	  --volume $(shell pwd)/data:/opt \
	  $(IMAGE_REPO)/$(REPO_USER)/${IMAGE_NAME}

stop:
	-${PODMAN} stop miniboot
	-${PODMAN} rm miniboot

tag:
	${PODMAN} tag ${IMAGE_NAME} ${IMAGE_REPO}/${REPO_USER}/${IMAGE_NAME}

push:
	${PODMAN} push $(IMAGE_REPO)/$(REPO_USER)/${IMAGE_NAME}

ipxe/src/bin/undionly.kpxe:
	mkdir -p bin
	cd ipxe/src ; make bin/undionly.kpxe

ipxe.efi:
	curl -O http://boot.ipxe.org/ipxe.efi

#
#
#
data:
	mkdir -p data

data/etc: data
	mkdir -p data/etc

data/etc/dhcpd.conf: data/etc templates/dhcpd.conf.j2 config_full.yaml
	jinja2 templates/dhcpd.conf.j2 config_full.yaml > data/etc/dhcpd.conf

data/etc/thttpd.conf: data/etc templates/thttpd.conf.j2 config_full.yaml
	jinja2 templates/thttpd.conf.j2 config_full.yaml > data/etc/thttpd.conf


data/www/pxe: data
	mkdir -p data/www/pxe


#
#
#
data/www/coreos: data
	mkdir -p data/www/coreos
	cd data/www/coreos ; \
	for ARCH in x86_64 aarch64 ; do \
	  ${PODMAN} run --privileged --pull=always --rm -v .:/data -w /data \
	    quay.io/coreos/coreos-installer:release download -a ${ARCH} -f pxe ; \
	  ln -s fedora-coreos-*-live-kernel-${ARCH} kernel-${ARCH} ; \
	  ln -s fedora-coreos-*-live-initramfs.${ARCH}.img initrd-${ARCH}.img ; \
	  ln -s fedora-coreos-*-live-rootfs.${ARCH}.img rootfs-${ARCH}.img ; \
	done

ports:
	firewall-cmd --add-service dhcp
	firewall-cmd --add-service tftp
	firewall-cmd --add-service http
