#
### Proxy/init.sls - defines proxy for apt/yum and system-wide proxy
#
{% if pillar['proxy'] | default(False) %}
{% set proxy = pillar['proxy'] %}

# system-wide proxy
/etc/profile:
  file.append:
    - text: |
         http_proxy={{ proxy }}
         export proxy

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
{% else %}
proxy error:
  test.show_notification:
    - text: '-- Unknown {{ grains['os_family'] }} OS family packager. will not define proxy.'  
{% endif %}

{% else %}
'-- This server does not use proxy.':
  test.nop
{% endif %}
