#
## named.sls - installs a bind9 dns named server
#
## ecgf - apr/2024
#

include:
  - linux_services.named.install
  - linux_services.named.open_ssh
  - linux_services.named.zones
  #- linux_services.named.close_ssh
  - linux_services.named.config
