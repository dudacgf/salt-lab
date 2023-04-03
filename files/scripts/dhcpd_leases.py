from isc_dhcp_leases import Lease, IscDhcpLeases
import sys

leases = IscDhcpLeases('/var/lib/dhcpd/dhcpd.leases')
leases_list = leases.get()

if len(leases_list) == 0:
  print('no lease at the moment')
  sys.exit(0)

print(f"HOST\t\t\tMAC\t\tIP\t\tEND")

for lease in leases_list:
  if lease.valid and lease.active:
    print(f"{lease.hostname}\t{lease.ethernet}\t{lease.ip}\t{lease.end}")

