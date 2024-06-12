#!/usr/bin/python3
import pycurl, syslog, dns.resolver, requests, argparse, configparser

# parse arguments
prog = 'godaddy ddns update'
version = '0.1'

parser = argparse.ArgumentParser(description='Update or create a GoDaddy DNS Record.', 
                                 prog=prog, allow_abbrev=True, 
                                 formatter_class=argparse.RawTextHelpFormatter,
                                 epilog= \
'''
GoDaddy customers can obtain values for the KEY and SECRET arguments by creating a production key at
https://developer.godaddy.com/keys/.

Use a credentials file with the following format:
[default]
api_key = a_godaddy_api_key
api_secret = a_godaddy_secret_that_wont_be_shown_again

''')

parser.add_argument('-V', '--version', action='version', version='{} {}'.format(prog, version))
parser.add_argument('-H', '--hostname', required=True, dest='hostname', type=str, help='DNS fully-qualified host name.')
parser.add_argument('-c', '--credentials_file', required=True, dest='credentials_file', type=str, help='File with GoDaddy\'s api key and secret.')
args = parser.parse_args()

# read credentials 
config = configparser.ConfigParser()
config.read(args.credentials_file)
apikey = config['default']['api_key']
secret = config['default']['api_secret']

# initialization
syslog.openlog("[godaddy_dns]")
syslog.syslog("start of execution")

# get current public address of this host
pub_addr = requests.get("https://ipv4.icanhazip.com").content.decode("utf-8").rstrip()
syslog.syslog(f"  current public address of {hostname}.{domain}: " + pub_addr)

# get current dns address of 'hostname.domain'
try:
    hostaddr = str(dns.resolver.resolve(args.hostname)[0])
    syslog.syslog(f"  current dns address of {args.hostname}: " + hostaddr)
except:
    hostaddr = '127.0.0.1'
    syslog.syslog(f"  using 127.0.0.1 as current dns address of {args.hostname} ")

# update dns record if necessary  
if hostaddr == pub_addr: 
    syslog.syslog("  got the same address. nothing to do.")

else:
    syslog.syslog("  public address changed. updating record at GoDaddy's")

    dnsdata='[{"data": "' + pub_addr + '", \
               "port": 80, \
               "priority": 10, \
               "protocol": "", \
               "service": "", \
               "ttl": 600, \
               "weight": 10}]'
    domain = '.'.join(args.hostname.split('.')[1:])
    hostname = args.hostname.split('.')[0]
    url =  "https://api.godaddy.com/v1/domains/" + domain + "/records/A/" + hostname
    authorization = 'Authorization: sso-key ' + apikey + ':' + secret

    connection = pycurl.Curl()

    connection.setopt(pycurl.URL, url)
    connection.setopt(pycurl.HTTPHEADER, ['Content-Type: application/json', 
                                          'Accept: application/json', authorization])
    connection.setopt(pycurl.CUSTOMREQUEST, "PUT")
    connection.setopt(pycurl.POSTFIELDS,dnsdata)

    connection.perform()

    response_code = connection.getinfo(connection.RESPONSE_CODE)
    if not (200 <= response_code <= 299):
        syslog.syslog(f"  There was a problem posting the update: ({response_code})")

    else:
        syslog.syslog(f"  {hostname}.{domain} ip address changed from {hostaddr} to {pub_addr}")

    connection.close()

# the end
syslog.syslog("end of execution")
syslog.closelog()

