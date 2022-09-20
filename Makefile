#!make

IMAGE_NAME=miniboot
TARBALL=${IMAGE_NAME}-oci.tgz
BUILD_CONTAINER_NAME=miniboot-build
IPXE_PATCH=ipxe.patch
REPO_NAME=quay.io
REPO_USER=markllama

DATA_DIR=./data

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
	  ${REPO_NAME}/${REPO_USER}/${IMAGE_NAME}

run:
	+podman run -d --rm --privileged --name miniboot --net=host \
	  --volume $(shell pwd)/data:/opt \
	  ${REPO_NAME}/${REPO_USER}/${IMAGE_NAME}

stop:
	-podman stop miniboot
	-podman rm miniboot

configs: ${DATA_DIR}/etc/thttpd.conf ${DATA_DIR}/etc/dhcpd_server.conf ${DATA_DIR}/etc/dhcpd_leases.conf $(DATA_DIR)/www

$(DATA_DIR)/etc:
	mkdir -p $(DATA_DIR)/etc

$(DATA_DIR)/www: 
	mkdir -p $(DATA_DIR)/www

$(DATA_DIR)/etc/thttpd.conf: $(DATA_DIR)/etc config.yaml
	jinja2 templates/thttpd.conf.j2 config.yaml > $(DATA_DIR)/etc/thttpd.conf

$(DATA_DIR)/etc/dhcpd_server.conf: $(DATA_DIR)/etc config.yaml
	jinja2 templates/dhcpd_server.conf.j2 config.yaml > $(DATA_DIR)/etc/dhcpd_server.conf

$(DATA_DIR)/etc/dhcpd_leases.conf: $(DATA_DIR)/etc config.yaml
	jinja2 templates/dhcpd_leases.conf.j2 config.yaml > $(DATA_DIR)/etc/dhcpd_leases.conf
