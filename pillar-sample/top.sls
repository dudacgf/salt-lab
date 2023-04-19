base:
  '*':
    - defaults
    - organization
    - users
    - hosts
    - labs
    - users
    - virt

  'G@os_family:Debian':
    - pkg_data_debian

  'G@os_family:RedHat':
    - pkg_data_redhat
{#
  'G@roles:webserver':
    - httpd

  'graylog*':
    - elasticsearch
    - mongodb
    - graylog

  'os:Windows':
    - match: grain
    - windows_servers
    - winlogbeat
#}
