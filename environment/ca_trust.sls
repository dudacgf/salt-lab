{% if pillar['org_ca']['self_signed'] | default(False) %}

ca-certificates:
  pkg.installed

{% if grains['os_family'] == 'RedHat' %}
copia certificado:
  file.managed:
    - name: /etc/pki/ca-trust/source/anchors/CA_Icatu.crt
    - source: {{ pillar['org_ca']['ca_file'] }}
    - user: root
    - group: root
    - mode: 0644

update-ca-trust:
  cmd.run:
    - require:
      - pkg: ca-certificates
      - file: copia certificado
      
{% elif grains['os_family'] == 'Debian' %}
copia certificado:
  file.managed:
    - name: /usr/local/share/ca-certificates/CA_Icatu.crt
    - source: {{ pillar['org_ca']['ca_file'] }}
    - user: root
    - group: root
    - mode: 0644

update-ca-certificates:
  cmd.run:
    - require:
      - pkg: ca-certificates
      - file: copia certificado
{% else %}
ca trust failure:
  test.fail_without_changes:
    - name: '*** OS not supported! ***'
    - failhard: True
{% endif %} # os_family
{% endif %} # org_ca:self_signed
