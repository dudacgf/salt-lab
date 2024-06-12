#
## bind9.sls - installs a bind9 dns named server
#
## ecgf - apr/2024
#

include:
  - linux_services.bind9.install
  - linux_services.bind9.open_ssh
  - linux_services.bind9.zones
  - linux_services.bind9.config
