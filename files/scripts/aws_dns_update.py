#!/usr/bin/python3
import syslog, dns.resolver, boto3, requests, argparse

# parse arguments
prog = 'aws ddns update'
version = '0.1'

parser = argparse.ArgumentParser(description='Update or delete AWS Route53 DNS Record.', 
                                 prog=prog, allow_abbrev=True, 
                                 formatter_class=argparse.RawTextHelpFormatter,
                                 epilog= \
'''
boto3 gets the key and secret from the file $USER/.aws/credentials. Those values can be generated using the
Security Credentials option at the User Menu at aws site

the format of the credentials file is:
[default]
aws_access_key_id = the_key_id_created_at_security_credentials
aws_secret_access_key = the_secret_created_at_security_credentials_and_not_shown_anymore_again

You also need a $USER/.aws/config file with the following format:
[default]

''')

parser.add_argument('-V', '--version', action='version', version='{} {}'.format(prog, version))
parser.add_argument('-H', '--hostname', required=True, dest='hostname', type=str, help='DNS fully-qualified host name.')
parser.add_argument('-z', '--zoneid', required=True, dest='zoneId', type=str, help='ZoneId of the zone being updated.')
args = parser.parse_args()

# initialization
syslog.openlog("[route53_dns]")
syslog.syslog("start of execution")

# get current public address of this host
pub_addr = requests.get("https://ipv4.icanhazip.com").content.decode("utf-8").rstrip()
syslog.syslog(f"  current public address of {args.hostname}: " + pub_addr)

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
    syslog.syslog("  public address changed. updating record at aws")

    cb = {'Changes': [
        { 'Action': 'UPSERT', 
          'ResourceRecordSet': {
              'Name': f'{args.hostname}', 
              'Type': 'A', 
              'ResourceRecords': [{'Value': pub_addr}], 
              'TTL': 60
            }
        }
    ]}

    try:
        r53 = boto3.client('route53')
        response = r53.change_resource_record_sets(HostedZoneId=args.zoneId, ChangeBatch=cb)
        changeId = response['ChangeInfo']['Id'].split('/')[-1]
        waiter = r53.get_waiter('resource_record_sets_changed')
        waiter.wait(Id=changeId,  WaiterConfig={'Delay': 10, 'MaxAttempts': 10})
    except Route53.Client.exceptions.NoSuchHostedZone as e:
        syslog.syslog(f'  No such hosted zone: {e}')
    except Route53.Client.exceptions.InvalidChangeBatch as e:
        syslog.syslog(f'  Error in changed batch: {e}')
    except Route53.Client.exceptions.InvalidInput as e:
        syslog.syslog(f'  Error invalid input: {e}')

    syslog.syslog(f'  {args.hostname} ip address changed from {hostaddr} to {pub_addr}')

# the end
syslog.syslog("end of execution")
syslog.closelog()

