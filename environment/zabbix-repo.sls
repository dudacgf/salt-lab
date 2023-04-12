{% if grains['os'] == 'Debian' %}
download repo deb:
  cmd.run: 
    - name: wget https://repo.zabbix.com/zabbix/6.0/debian/pool/main/z/zabbix-release/zabbix-release_6.0-4+debian11_all.deb -O /tmp/zabbix-release.deb

zabbix_repo:
  cmd.run:
    - name: dpkg -i /tmp/zabbix-release.deb
    - require:
      - cmd: download repo deb

{% elif grains['os'] == 'Ubuntu' %}
download repo deb:
  cmd.run:
    - name:  wget https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.0-4+ubuntu22.04_all.deb -O /tmp/zabbix-release.deb

zabbix_repo:
  cmd.run:
    - name: dpkg -i /tmp/zabbix-release.deb
    - require:
      - cmd: download repo deb

{% elif grains['os_family'] == 'RedHat' %}
zabbix_repo:
    - name:  rpm -Uvh https://repo.zabbix.com/zabbix/6.0/rhel/9/x86_64/zabbix-release-6.0-4.el9.noarch.rpm

exclude zabbix from epel:
  file.line:
    - name: /etc/yum.repos.d/epel.repo
    - mode: insert
    - after: '\[epel\]'
    - content: 'excludepkgs=zabbix*'

{% elif grains['os_family'] == 'Windows' %}
zabbix_repo:
  test.nop:
    - name: '** win repo used'
{% else %}

'** OS Not Supported **':
  test.fail_without_changes:
    - failhard: True
{% endif %}
