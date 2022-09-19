#!make

IMAGE_NAME=miniboot
TARBALL=${IMAGE_NAME}-oci.tgz
BUILD_CONTAINER_NAME=miniboot-build
IPXE_PATCH=ipxe.patch

#
# Targets to build the container image and push it to the repo
#
build: ipxe/src/bin/undionly.kpxe ipxe.efi
	buildah unshare ./build.sh $(BUILD_CONTAINER_NAME) $(IMAGE_NAME)


ipxe/src/Makefile.housekeeping: ipxe.patch
	cd ipxe ; \
  patch -p0 < ../${IPXE_PATCH}

ipxe/src/bin/undionly.kpxe: ipxe/src/Makefile.housekeeping
	mkdir -p bin
	cd ipxe/src ; make bin/undionly.kpxe

ipxe.efi:
	curl -O http://boot.ipxe.org/ipxe.efi

$(TARBALL): build
	podman save --format oci-archive ${IMAGE_NAME} --output $(IMAGE_NAME)-oci.tgz

#
# Remove artifacts to start again
#
clean:
	-rm -f $(TARBALL)
	-buildah delete $(BUILD_CONTAINER_NAME)
	-podman rmi ${IMAGE_NAME}

realclean: clean
	rm -f ipxe.efi
	cd ipxe/src ; make clean

#
# Test and run the server container
#
cli:
	+podman run -it --rm --privileged --name miniboot --net=host \
	  --volume $(shell pwd)/data:/opt \
	  --entrypoint=/bin/bash \
	  ${IMAGE_NAME}

run:
	+podman run -d --rm --privileged --name miniboot --net=host \
	  --volume $(shell pwd)/data:/opt \
	  ${IMAGE_NAME}

stop:
	-podman stop miniboot
	-podman rm miniboot

configs: data/etc/thttpd.conf data/etc/dhcpd.conf

data/etc:
	mkdir -p data/etc

data/etc/thttpd.conf: data/etc config.yaml
	jinja2 templates/thttpd.conf.j2 config.yaml > data/etc/thttpd.conf

data/etc/dhcpd.conf: data/etc config.yaml
	jinja2 templates/dhcpd.conf.j2 config.yaml > data/etc/dhcpd.conf

data/etc/dhcpd_leases.conf: data/etc config.yaml
	jinja2 templates/dhcpd_leases.conf.j2 config.yaml > data/etc/dhcpd_leases.conf
