{% if grains['os_family'] == 'Debian' %}
/tmp/vivaldi.pub:
  file.managed:
    - source: https://repo.vivaldi.com/archive/linux_signing_key.pub
    - skip_verify: True

convert pub to gpg:
  cmd.run:
    - name: "cat /tmp/vivaldi.pub | gpg --dearmor > /usr/share/keyrings/vivaldi.gpg"
    - require:
      - file: /tmp/vivaldi.pub

repo vivaldi:
  pkgrepo.managed:
    - name: "deb [arch=amd64 signed-by=/usr/share/keyrings/vivaldi.gpg] https://repo.vivaldi.com/archive/deb/ stable main"
    - baseurl: https://repo.vivaldi.com
    - humanname: Vivaldi
    - file: /etc/apt/sources.list.d/vivaldi.list
    - require:
      - cmd: convert pub to gpg
{% endif %}

install vivaldi:
  pkg.installed:
    - name: vivaldi-stable
    - require:
      - repo vivaldi
    - refresh: True
