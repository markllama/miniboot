#!/bin/python3

import argparse
import dns.resolver
import ipaddress
import jinja2
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

def parse_options():
    """
    TBD
    """

    parser = argparse.ArgumentParser()
    
    parser.add_argument("--interface")
    parser.add_argument("--config-file", default='config.yaml')
    parser.add_argument("--template-dir", default='templates')
    parser.add_argument("--output-dir", default='data')

    return parser.parse_args()

def query_network(interface):
    #
    # Query the network bits
    #
    #network['interface'] = opts.interface
    network['interface'] = interface

    iface = netifaces.ifaddresses(network['interface'])
    netaddr = iface[netifaces.AF_INET][0]

    network['addr'] = netaddr['addr']    
    network['mask'] = netaddr['netmask']
    # get the base address for the network interface
    network['base'] = str(ipaddress.ip_network(
        netaddr['addr'] + '/' + netaddr['netmask'], strict=False).network_address)

    network['gate'] = '.'.join(network['base'].split('.')[0:3] + ['1'])
    #r = pyroute2.IPRoute().route('get', dst='8.8.8.8')[0]['attrs']
    #network['gate'] = [x[1] for x in r if x[0] == 'RTA_GATEWAY'][0]

    return network

def query_resolver():
    r = dns.resolver.Resolver()

    res['domain'] = str(r.domain) if str(r.domain) != '.' else str(r.search[0])
    res['nameserver'] = str(r.nameservers[0])

    return res

#
#
#
service_templates = ('dhcpd.conf', 'thttpd.conf')
host_templates = ('boot.ipxe', 'config.ign')


if __name__ == "__main__":

    opts = parse_options()

    # Load the user configuration file
    config = yaml.load(open(opts.config_file), yaml.Loader)

    config['network'] = query_network(config['interface'])
    config['dns'] = query_resolver()
                                      
    #print(yaml.dump(config))

    # Generate service configuration files
    for template_file in service_templates:
        template = jinja2.Template(open(os.path.join(opts.template_dir, template_file + '.j2')).read())
        rendered_file = open(os.path.join(opts.output_dir, template_file), 'w')
        rendered_file.write(template.render(config))
        rendered_file.close()
                             
    for template_file in host_templates:
        template = jinja2.Template(open(os.path.join(opts.template_dir, template_file + '.j2')).read())
        for i, host in enumerate(config['clients']):
            rendered_file = open(os.path.join(opts.output_dir, "www", f"{host['name']}-{template_file}"), 'w')
            rendered_file.write(template.render(config, client_number=i))
            rendered_file.close()
            

    #print(dhcp_template.render(config))

    
