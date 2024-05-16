##
# vault.sls - install a vault by hashicorp secrets database in a minion
#

{%- if grains.os_family == 'Debian' %}
vault gpg key:
  cmd.run:
    - name: 'wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/vault.gpg'
    - user: root
    - group: root
    - mode: 644

vault repo:
  pkgrepo.managed:
    - name: "deb [signed-by=/etc/apt/trusted.gpg.d/vault.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
    - humanname: Vault by Hashicorp
    - file: /etc/apt/sources.list.d/vault.list
    - key_url: https://apt.releases.hashicorp.com/gpg
{%- elif grains.os_family == 'RedHat' %}
vault repo:
  pkgrepo.managed:
    - name: Vault
    - file: /etc/yum.repos.d/vault.repo
    - enabled: True
    - baseurl: https://rpm.releases.hashicorp.com/RHEL/$releasever/$basearch/stable
    - gpgcheck: 1
    - gpgkey: https://rpm.releases.hashicorp.com/gpg
{%- else %}
failure:
  test.fail_without_changes:
    - text: '*** vault: OS not supported. Will not install ***'
    - failhard: True
{% endif %}

# installs vault 
vault:
  pkg.installed:
    - require:
      - vault repo
