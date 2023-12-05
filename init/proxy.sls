#
### Proxy/init.sls - defines proxy for apt/yum and system-wide proxy
#

{% if pillar['proxy'] %}
{% set proxy = pillar['proxy'] %}

# system-wide proxy
/etc/profile:
  file.append:
    - text: |
         http_proxy={{ proxy }}
         https_proxy={{ proxy }}
         export http_proxy https_proxy

# apt/yum proxy
{% if grains['os_family'] == 'Debian' %}
/etc/apt/apt.conf.d/00-proxy.conf:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - backup: minion
    - contents: [
        'Acquire::http::Proxy "{{ proxy }}";',
        'Acquire::https::Proxy "{{ proxy }}";',
      ]
{% elif grains['os_family'] == 'RedHat' %}
/etc/dnf/dnf.conf:
  file.append:
    - text: |
        proxy={{ proxy }}
{% elif grains['os_family'] == 'Suse' %}
/etc/sysconfig/proxy:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents: |
        PROXY_ENABLED="yes"
        HTTP_PROXY="{{ proxy }}"
        HTTPS_PROXY="{{ proxy }}"
        NO_PROXY="localhost, 127.0.0.1"
{% else %}
proxy error:
  test.show_notification:
    - text: '-- Unknown {{ grains['os_family'] }} OS family packager. will not define proxy.'  
{% endif %}

# salt-minion packager proxy
/etc/salt/minion.d/00-proxy.conf:
  file.managed:
    - contents:
      - "proxy_host: {{ proxy | regex_replace('^.*://(.*):.*', '\\1') }}"
      - "proxy_port: {{ proxy | regex_replace('.*:(.*)$', '\\1') }}"
      - "no_proxy: [ '127.0.0.1', 'localhost' ]"

setproxy restart salt minion:
  cmd.run:
    - name: 'salt-call --local service.restart salt-minion'
    - bg: True
    - require:
      - file: /etc/salt/minion.d/00-proxy.conf
{% else %}
'-- This server does not use proxy.':
  test.nop
{% endif %}
