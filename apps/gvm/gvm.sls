#
## gvm.sls - instala gvm [ex-openvas] e inicia seu setup


#
# Adiciona o repositório atomicorp (gvm [ex-openVAS] %}

{% if grains['os_family'] == 'RedHat' %}
gvm_repo:
  pkgrepo.managed:
    - name: atomic
    - humanname:  Rocky / CentOS / Red Hat Enterprise Linux $releasever - atomic
    - enabled: True
    - mirrorlist: https://updates.atomicorp.com/channels/mirrorlist/atomic/rocky-$releasever-$basearch
    - gpgcheck: 1
    - gpgkey: https://www.atomicorp.com/RPM-GPG-KEY.atomicorp.txt

# instala 
gvm:
  pkg.installed:
    - refresh: True
    - require:
      - gvm_repo

copia sysconfig gsad:
  file.managed:
    - name: /etc/sysconfig/gsad
    - source: salt://files/services/gvm/gsad.conf
    - user: root
    - group: root
    - mode: 644

gvm setup:
  module.run:
    - cmd.run:
      - name: gvm-setup
      - cmd: gvm-setup
      - stdin: |
          {{ pillar['gsad_admin_pw'] }}
          {{ pillar['gsad_admin_pw'] }}

gsad.service:
  service.running:
    - restart: true
    - watch:
      - file: copia sysconfig gsad

{% else %}
gvm_repo:
  test.fail_without_changes:
      - name: '*** GVM não será instalado neste OS.'
{% endif %}

