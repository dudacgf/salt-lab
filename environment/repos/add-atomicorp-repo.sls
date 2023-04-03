#
# Adiciona o repositório atomicorp (gvm [ex-openVAS] %}

{% if grains['os_family'] == 'Debian' %}
debian_elasticsearch:
  pkgrepo.managed:
    - name: deb [trusted=yes] https://updates.atomicorp.com/channels/atomic/debian bullseye/amd64/ 
    - humanname: Debian $releasever - atomic
    - dist: stable
    - file: /etc/apt/sources.list.d/atomic.list
    - key_url: https://www.atomicorp.com/RPM-GPG-KEY.atomicorp.txt
{% elif grains['os_family'] == 'Redhat' %}
redhat_elasticsearch:
  pkgrepo.managed:
    - name: atomic
    - humanname:  Rocky / CentOS / Red Hat Enterprise Linux $releasever - atomic
    - enabled: True
    - mirrorlist: https://updates.atomicorp.com/channels/mirrorlist/atomic/centos-$releasever-$basearch
    - gpgcheck: 1
    - gpgkey: https://www.atomicorp.com/RPM-GPG-KEY.atomicorp.txt
{% endif %}

