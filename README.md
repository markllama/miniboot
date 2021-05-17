# Miniboot

Miniboot is a software container that helps boot single host via PXE

It includes a DHCP server, a TFTP server and the PXELINUX files needed to boot
a memory resident Linux on a single host.

The user provides the network parameters for the DHCP server and the file URLs
for the Linux kernel and ramdisk. 


## DHCP Configuration

In the first phase of a PXE boot, the client computer broadcasts a DHCP query packet. If there
is a DHCP server on the network and if it is offering addresses from an open pool or if there is
a lease reservation for the client MAC address, the DHCP server will respond. The DHCP response
will include at least the IP address and net mask. It often will include the default route, and a
list of name and time servers.  These are sufficent for ordinary membership in network.

DHCP can offer a variety of additional values for the client to use, and the PXE specification
defines two values, _nextserver_ (option 66) and _filename_ (option 67). The _nextserver_ value is
the IP address of a host running a TFTP server. The _filename_ value is the location of a bootable
image on the TFTP server.

On recieving the DHCP reply and configuring the NIC, the client host issues a TFTP get request for
the file indicated. When it recieves the file, it loads that file into memory and executes it.
The file used most commonly is _pxelinux.0_ from the _syslinux_ package. 

The DHCP server configuration to boot a single client 

* Network Base Address
* Network Mask (dotted quad or CIDR mask)
* Default Router
* DNS IP address list
* MAC Address of the client
* IP Address of the client
* IP Address of a TFTP Server
* File path of the pxelinux.0 binary

## TFTP Server

The TFTP server provides most of the files that the client uses to boot and configure the 
memory unix. The files are pulled in a sequence as the client boots.

1. _pxelinux.0_  
   The first executable binary. The PXE client loads this into memory and executes it.
   The PXELINUX binary issues as set of queries back to the same server it came from.

1. _ldlinux.c32_  
   This is a library required by _pxelinux.0_ when running in a BIOS environment

1. _pxelinux.cfg/*_  
   The _pxelinux.0_ attempts to pull a series of files from the TFTP server. The names of these  
   files are derived first from the MAC address of the client NIC and then from the IP address  
   provided by DHCP.  
   
   1. MAC Address  
      01-<NN>-<NN>-<NN>-<NN>-<NN>-<NN>  
      The two digit values are the hexadecimal values of each of the bytes of the MAC address
      
   1. IP address  
      If the previous file is not found, _pxelinux.0_ requests a series of file names based on  
      The IP address of the NIC. The first file name is the IP address expressed as a series of  
      hexadecimal digits. Each successive file name contains one fewer character. For example:
      
      IP address 192.168.1.44 would result in the following sequence of queries:  
      
      C0A8012C  
      C0A8012  
      C0A801  
      C0A80  
      ...  
      
      If the TFTP server returns one of these files, _pxelinux.0_ uses it. If not, it proceeds  
      to the next in the series until it finds one or all are exhausted.
      
   1. default  
      The final query, if none of the previous files is found is for a file named _default_
      
  
   
   


## References

* [ISC DHCP Server]()
* [TFTP Server]()
* [SYSLINUX]()
* [PXE: Pre-Execution Environment](https://en.wikipedia.org/wiki/Preboot_Execution_Environment)

* [Installing Fedora CoreOS from PXE](https://docs.fedoraproject.org/en-US/fedora-coreos/bare-metal/#_installing_from_pxe)
