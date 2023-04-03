#
## gvm.sls - instala gvm [ex-openvas] e inicia seu setup


#
# Adiciona o repositório atomicorp (gvm [ex-openVAS] %}

{% if grains['os'] == 'Debian' %}
gvm_repo:
  pkgrepo.managed:
    - name: 'deb [trusted=yes] https://updates.atomicorp.com/channels/atomic/debian bullseye/amd64/ '
    - file: /etc/apt/sources.list.d/atomic.list
    - key_url: salt://files/env/RPM-GPG-KEY.atomicorp.txt
{% elif grains['os_family'] == 'RedHat' %}
gvm_repo:
  pkgrepo.managed:
    - name: atomic
    - humanname:  Rocky / CentOS / Red Hat Enterprise Linux $releasever - atomic
    - enabled: True
    - mirrorlist: https://updates.atomicorp.com/channels/mirrorlist/atomic/rocky-$releasever-$basearch
    - gpgcheck: 1
    - gpgkey: https://www.atomicorp.com/RPM-GPG-KEY.atomicorp.txt
{% elif grains['os'] == 'Ubuntu' %}
gvm_repo:
  test.nop:
      - name: '*** gvm já disponível. Nada a fazer'
{% endif %}

#
# instala 
gvm:
  pkg.installed:
    - refresh: True
    - require:
      - gvm_repo

copia systemd gsad:
  file.managed:
    - name: /etc/sysconfig/gsad
    - source: salt://files/services/gvm/gsad.conf
    - user: root
    - group: root
    - mode: 644

gsad.service:
  service.running:
    - restart: true
    - watch:
      - file: copia systemd gsad
