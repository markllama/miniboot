# Miniboot

Miniboot is a software container that helps boot single host via PXE

It includes a DHCP server, a TFTP server and the PXELINUX files needed to boot
a memory resident Linux on a single host.

The user provides the network parameters for the DHCP server and the file URLs
for the Linux kernel and ramdisk. 


## References

* [ISC DHCP Server]()
* [TFTP Server]()
* [SYSLINUX]()
* [PXE: Pre-Execution Environment](https://en.wikipedia.org/wiki/Preboot_Execution_Environment)

* [Installing Fedora CoreOS from PXE](https://docs.fedoraproject.org/en-US/fedora-coreos/bare-metal/#_installing_from_pxe)
