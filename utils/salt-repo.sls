#
# Adiciona o repositório do salt 2023
#

{% if grains['os_family'] == 'Debian' %}
add salt repo:
  pkgrepo.managed:
    - name: deb https://repo.saltproject.io/salt/py3/ubuntu/22.04/amd64/latest {{ grains['oscodename'] }} main
    - humanname: Salt 2023 repo
    - file: /etc/apt/sources.list.d/salt.list
    - comps: main
    - key_url: https://repo.saltproject.io/salt/py3/ubuntu/22.04/amd64/SALT-PROJECT-GPG-PUBKEY-2023.gpg
{% elif grains['os_family'] == 'RedHat' %}
{% set osmr = grains['osmajorrelease'] %}
add salt repo:
  pkgrepo.managed:
    - name: salt
    - enabled: True
    - baseurl: https://repo.saltproject.io/salt/py3/redhat/{{ osmr }}/x86_64/latest
    - gpgcheck: 1
    - gpgkey: https://repo.saltproject.io/salt/py3/redhat/{{ osmr }}/x86_64/SALT-PROJECT-GPG-PUBKEY-2023.pub
{% else %}
failure:
  test.fail_without_changes:
    - text: '*** salt: OS not supported. Will not install ***'
    - failhard: True
{% endif %}

