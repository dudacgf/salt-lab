##
#
## httpd.sls - install httpd + mod_ssl + mod_rewrite (if Debian/Ubuntu)
#
## (c) ecgf - Jun/2021
# 
##

include:
  - linux_services.apache.install
  - linux_services.apache.config
  - linux_services.apache.config_ssl
#  - linux_services.apache.hosts


