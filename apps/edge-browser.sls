{% if grains['os_family'] == 'Debian' %}
{%- if not salt['file.file_exists']('/usr/share/keyrings/microsoft.gpg') %}
/tmp/microsoft.asc:
  file.managed:
    - source: https://packages.microsoft.com/keys/microsoft.asc 
    - skip_verify: True

convert asc to gpg:
  cmd.run:
    - name: "cat /tmp/microsoft.asc | gpg --dearmor > /usr/share/keyrings/microsoft.gpg"
    - require:
      - file: /tmp/microsoft.asc
{%- endif %}

repo edge:
  pkgrepo.managed:
    - name: "deb [signed-by=/usr/share/keyrings/microsoft.gpg arch=amd64] https://packages.microsoft.com/repos/edge stable main"
    - humanname: Debian - Edge Browser
    - file: /etc/apt/sources.list.d/microsoft-edge.list
{% endif %}

install edge:
  pkg.installed:
    - name: microsoft-edge-stable
    - require:
      - repo edge
    - refresh: True
