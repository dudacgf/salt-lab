# prepares primary and secondary for a scp file transfer using root login
{%- import_yaml "maps/pkg_data/by_os_family.yaml" as pkg_data %}
{%- set pkg_data = salt.grains.filter_by(pkg_data) -%}

{%- if 'named' in pillar and pillar.named.type | default('primary') | lower == 'primary' %}
{%- for secondary in pillar.named.secondaries | default([]) %}
match {{ secondary }} create:
  file.managed:
    - name: /etc/ssh/sshd_config.d/13-match-{{secondary}}
    - user: root
    - group: root
    - mode: 0600
    - contents: |
        Match Address {{secondary}}
            PermitRootLogin yes
{%- endfor %}
open ssh restart service:
  cmd.run:
    - name: 'systemctl restart sshd'
{%- elif 'named' in pillar and pillar.named.type | default('primary') | lower == 'secondary' %}
{{ pkg_data.python3.pip_version }} install scp: cmd.run
open ssh send privkey:
  file.managed:
    - name: /root/.ssh/salt_vg_ed25519
    - user: root
    - group: root
    - mode: 0400
    - source: salt://files/pki/salt_vg_ed25519
{% endif %}
