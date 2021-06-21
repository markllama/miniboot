# Build Instructions for Miniboot Container

The miniboot container image requires one special binary that I could not find pre-built.
IPXE is an extension of standard PXE booting. It can be chain-loaded through standard DHCP/PXE
booting and provides better control of the kernel and disk image loading. CoreOS uses an
initramdisk image and a separate root disk image. IPXE makes it simpler to specify how to boot
the system

# Build the `undionly.kpxe` binary for IPXE chain loading

The chainloading binary `undionly.kpxe` is built from the [ipxe](http://git.ipxe.org) git
repository. When cloning use `--recurse-submodules` to check out the _ipxe_ submodule
repository at the same time.

# Build the container image


    make o
