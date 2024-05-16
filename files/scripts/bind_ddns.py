#!/usr/bin/env python3
###
## bind_ddns.py - updates or deletes a RRset in a dns zone
#
## (c) ecgf - mai/2024
#
# update_zone.py -a update -k /root/.tsigkeys -z example.com -d test -t A -i 192.168.0.1 -s 192.168.10.1
#
# args:
# -a|--action - action to be performed: update or delete. defaults to update 
#               update adds the RRset if it not exits yet.
#
# -k|--keyring-secrets-file - file in yaml format with keyring name and its secret
#      format:
#      << zone >>:
#          name: tsig_update_key_name
#          secret: tsig_update_key_secret==
# 
# -z|--zone - zone to be updated
#
# -d|--domain-name - domainname to be updated
#
# -t|--record-type - type of record. defaults to A
#
# -i|--info - information to be updated for {domain}.{zone}. defaults to ipv4
#
# -s|--dns-server - dns server to send the update message. defaults to localhost
#
# 
# TODO: try to add PTR record when record-type is A or AAAA
#

import argparse
import sys
import socket
import ipaddress

import dns.tsigkeyring
import dns.update
import dns.query
import yaml

#
# check and parse args
PROG_DESCRIPTION="update zone"
KEYRING_FILE_HELP="Path to a .yml file containing a tsgikeyring name and secret\n"

# parse arguments
def get_local_ip_address():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    s.connect(("8.8.8.8", 80))
    return s.getsockname()[0]

def is_ip_address(ip2test):
    try:
        ipaddress.ip_address(ip2test)
        return True
    except ValueError:
        return False

def resolve_dns_name(dnsname):
    try:
        ip = socket.gethostbyname(dnsname)
        return ip
    except:
        return '127.0.0.1'

parser = argparse.ArgumentParser(
    prog="bind_ddns",  # TODO figure out why I need this in my code for -h to show correct name
    description=PROG_DESCRIPTION,
    allow_abbrev=True,
    formatter_class=argparse.ArgumentDefaultsHelpFormatter
)
parser.add_argument("-a", "--action", dest="action", help="Action to be executed",
                    required=False, choices=['update', 'u', 'delete', 'd'], default='update')
parser.add_argument("-k", "--keyring-secrets-file", dest="keyring_file",help=KEYRING_FILE_HELP,
                    required=True)
parser.add_argument("-z", "--zone", dest="zone",help="Zone to be updated",
                    required=True)
parser.add_argument("-d", "--domain-name", dest="domain_name",help="Domain name to be updated or deleted.",
                    required=True)
parser.add_argument("-t", "--record-type", dest="record_type",help="Type of record to be updated or deleted.",
                    required=False, default='A')
parser.add_argument("-i", "--info", dest="info",help="Information to be updated in record type {t} of {domainname}.{zone}",
                    required=False, default=get_local_ip_address())
parser.add_argument("-s", "--dns-server", dest="dns_server",help="DNS server to send the message",
                    required=False, default="127.0.0.1")
args = parser.parse_args()

# translate dns_server to ip address if needed
if not is_ip_address(args.dns_server):
    dns_server = resolve_dns_name(args.dns_server)
else:
    dns_server = args.dns_server

# initialize tsigkeyring object
with open(args.keyring_file) as k:
    try:
        keyread = yaml.safe_load(k)
    except yaml.YAMLError as exc:
        print(exc)
        sys.exit(1)

keyring = dns.tsigkeyring.from_text({
    keyread[args.zone]['name'] : keyread[args.zone]['secret']
})

# initialize updateMessage object
message = dns.update.UpdateMessage(args.zone, keyring=keyring)
if args.action in ['u', 'update']:
    message.replace(args.domain_name, 300, args.record_type, args.info)
else:
    message.delete(args.domain_name, args.record_type)

# finally execute the update
try:
    response = dns.query.udp(message, dns_server)
except dns.tsig.PeerBadKey as exc:
    print(exc)
    sys.exit(1)
except ValueError as exc:
    print(f'Value Error: {dns_server}')
    sys.exit(1)

print(response.rcode())
