{%- import_yaml "maps/pkg_data/" + grains.os_family | lower + ".yaml" as pkg_data %}
{% if grains['os'] == 'Ubuntu' %}
add duo repo:
  pkgrepo.managed:
    - name: deb [arch=amd64] https://pkg.duosecurity.com/Ubuntu jammy main
    - humanname: Duo Security Repository
    - file: /etc/apt/sources.list.d/duo.list
    - key_url: https://duo.com/DUO-GPG-PUBLIC-KEY.asc
    - apt-key: False
{% elif grains['os'] == 'Debian' %}
add duo repo:
  pkgrepo.managed:
    - name: deb [arch=amd64] https://pkg.duosecurity.com/Debian bullseye main
    - humanname: Duo Security Repository
    - file: /etc/apt/sources.list.d/duo.list
    - key_url: https://duo.com/DUO-GPG-PUBLIC-KEY.asc
{% elif grains['os_family'] == 'RedHat' %}
add duo repo:
  pkgrepo.managed:
    - name: Duo Security Repository
    - enabled: True
    - baseurl: https://pkg.duosecurity.com/RedHat/9/x86_64
    - gpgcheck: 1
    - gpgkey: https://duo.com/DUO-GPG-PUBLIC-KEY.asc
    - file: /etc/yum.repos.d/duo.repo
{% else %}
failure:
  test.fail_without_changes:
    - text: '*** elasticsearch: OS not supported. Will not install ***'
    - failhard: True
{% endif %}

{{ pkg_data.duo.name }}:
  pkg.installed:
    - require:
      - pkgrepo: add duo repo

/etc/duo/pam_duo.conf:
  file.managed:
    - contents: |
        [duo]
        ikey = {{ pillar['duo']['ikey'] }}
        skey = {{ pillar['duo']['skey'] }}
        host = {{ pillar['duo']['host'] }}
        failmode = safe
        pushinfo = yes
        groups = users,!scanacct

/etc/duo/login_duo.conf:
  file.managed:
    - contents: |
        [duo]
        ikey = {{ pillar['duo']['ikey'] }}
        skey = {{ pillar['duo']['skey'] }}
        host = {{ pillar['duo']['host'] }}
        failmode = safe
        pushinfo = yes
        groups = users,!scanacct
