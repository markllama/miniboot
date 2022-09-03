# Miniboot

Miniboot is a software container that helps boot single host via PXE

It includes a DHCP server, a TFTP server and the PXELINUX files needed to boot
a memory resident Linux on a single host.

The user provides the network parameters for the DHCP server and the file URLs
for the Linux kernel and ramdisk. 

## Building the Container Image

## Container Configuration

* interface

* http.port

### Network Parameters

### Host Definitions

* hostname
* mac_address
* ipv4_address

### User Definitions

* username
* password_hash
* public_key

### Example Config File

~~~
---
# The name of the interface to listen on
interface: br-data

# The HTTP port used once iPXE is launched
http:
  port: 8080

# Optional, if observing or logging in on the serial console
console: ttyS1,115200n8

# A list of MAC/IP address pairs for the clients to be booted 
# - The IP addresses must be in an IP range on the interface above
clients: 
  - hostname:     node1
    mac_address:  00:30:48:9F:C2:02    # MAC address to respond to
    ipv4_address: 172.18.0.21          # IP address to assign

  - hostname:     node2
    mac_address:  00:25:90:6a:75:b4    # MAC address to respond to
    ipv4_address: 172.18.0.22          # IP address to assign

  - hostname:     node3
    mac_address:  00:25:90:60:b6:14    # MAC address to respond to
    ipv4_address: 172.18.0.23          # IP address to assign
# ...

users:
 - name: core
   # mkpasswd --method=sha256crypt
   # cleartext: core - replace with your value if desired
   password_hash: "$1$ebTQlHxO$unj0Wz5STH9.tMn1yFWYE0"
   # SSH public key
   public_key: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJDsdnCbVpUYOiqvjys/Ub4VP7Kpe7X98MIUREygC+9Q user@example.com"
~~~

## Generating Configuration Files

### `/etc` files

#### `dhcpd.conf`

#### `thttpd.conf`

### Boot Configuration Files

#### iPXE Configuration Files

#### OS Configuration Files

### CoreOS Binaries



## References

* [ISC DHCP Server]()
* [TFTP Server]()
* [SYSLINUX]()
* [PXE: Pre-Execution Environment](https://en.wikipedia.org/wiki/Preboot_Execution_Environment)
* iPXE
* [Installing Fedora CoreOS from PXE](https://docs.fedoraproject.org/en-US/fedora-coreos/bare-metal/#_installing_from_pxe)
