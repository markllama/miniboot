#!/bin/python3

import argparse
import dns.resolver
import ipaddress
import netifaces
import os
import pyroute2
import sys
import yaml

"""
network:
  interface: {name}
  base: {base}
  mask: {mask}
  addr: {addr}
  gateway: {gate}

dns:
  domain: {domain}
  nameserver: {nameserver}
"""

network = {
    'interface': None,
    'base': None,
    'mask': None,
    'addr': None,
    'gate': None
}

res = {
    'domain': None,
    'nameserver': None
}


if __name__ == "__main__":

    network['interface'] = sys.argv[1]

    iface = netifaces.ifaddresses(network['interface'])
    netaddr = iface[netifaces.AF_INET][0]

    network['addr'] = netaddr['addr']    
    network['mask'] = netaddr['netmask']
    # get the base address for the network interface
    network['base'] = str(ipaddress.ip_network(
        netaddr['addr'] + '/' + netaddr['netmask'], strict=False).network_address)
    
    r = pyroute2.IPRoute().route('get', dst='8.8.8.8')[0]['attrs']
    network['gate'] = [x[1] for x in r if x[0] == 'RTA_GATEWAY'][0]

    r = dns.resolver.Resolver()

    res['domain'] = str(r.domain) if str(r.domain) != '.' else str(r.search[0])
    res['nameserver'] = str(r.nameservers[0])
    
    print(yaml.dump({'network': network, 'dns': res}))
