# prepares primary and secondary for a scp file transfer using root login
{%- import_yaml "maps/pkg_data/" + grains.os_family | lower + ".yaml" as pkg_data %}

{%- if 'named' in pillar and pillar.named.type | default('primary') | lower == 'primary' %}
{%- for secondary in pillar.named.secondaries %}
/etc/ssh/sshd_config.d/13-match-{{secondary}}:
  file.absent
{%- endfor %}
'systemctl restart sshd': cmd.run
{%- elif 'named' in pillar and pillar.named.type | default('primary') | lower == 'secondary' %}
/root/.ssh/salt_vg_ed25519:
  file.absent
{% endif %}
