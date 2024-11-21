#
# Adiciona o repositório do salt 2023
#

{% if grains['os_family'] == 'Debian' %}
/etc/apt/sources.list.d/salt.list:
  file.absent
add salt repo:
  pkgrepo.managed:
    - name: deb [arch=amd64] https://packages.broadcom.com/artifactory/saltproject-deb/ stable main
    - humanname: Salt 2023 repo
    - file: /etc/apt/sources.list.d/salt.list
    - comps: main
    - key_url: https://packages.broadcom.com/artifactory/api/security/keypair/SaltProjectKey/public
{% elif grains['os_family'] == 'RedHat' %}
{% set osmr = grains['osmajorrelease'] %}
add salt repo:
  pkgrepo.managed:
    - name: salt
    - enabled: True
    - baseurl: https://packages.broadcom.com/artifactory/saltproject-rpm/
    - gpgcheck: 1
    - gpgkey: https://packages.broadcom.com/artifactory/api/security/keypair/SaltProjectKey/public
{% else %}
failure:
  test.fail_without_changes:
    - text: '*** salt: OS not supported. Will not install ***'
    - failhard: True
{% endif %}

