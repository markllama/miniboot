# Miniboot

Miniboot is a software container that helps boot single host via PXE

It includes a DHCP server, a TFTP server and the iPXE files to needed
to initiate a boot/install on a PXE enabled server. The user must
provides the server configuration files and the PXE boot payload when
the container is instantiated.

## Building the Container Image

## Container Configuration

    /opt/miniboot/
        etc/
            dhcpd.conf
            thttpd.conf
        www/
            ipxe/
                <nodename>.ipxe
            coreos/
                kernel
                initrd.img
                rootfs.img
            fcos/
                <nodename>/
                    node.ign
                    <interface>.nmconnection

## Running the PXE boot service

    podman run -d --privileged --name miniboot \
      --net=host \
      --volume /opt/miniboot:/opt \
      quay.io/markllama/miniboot
      
## References

* [ISC DHCP Server]()
* [TFTP Server]()
* [SYSLINUX]()
* [PXE: Pre-Execution Environment](https://en.wikipedia.org/wiki/Preboot_Execution_Environment)
* iPXE
* [Installing Fedora CoreOS from PXE](https://docs.fedoraproject.org/en-US/fedora-coreos/bare-metal/#_installing_from_pxe)
