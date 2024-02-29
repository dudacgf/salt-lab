#
## netshares.sls - mount shares defined in host pillar file
#
#

{% if pillar['netshares'] | default('none') != 'none' %}
cifs-utils:
  pkg.installed

{% for share in pillar['netshares'] | default([]) %}
"{{ pillar['netshares'][share]['mount'] }}":
  file.directory:
    - user: {{ pillar['netshares'][share]['user'] }}
    - group: {{ pillar['netshares'][share]['group'] }}
    - mode: 0750
    - makedirs: True

"fstab {{ pillar['netshares'][share]['mount'] }}":
  file.append:
    - name: /etc/fstab
    - text:  |
        # windows share {{ pillar['netshares'][share]['mount'] }}
        {{ pillar['netshares'][share]['share'] }} {{ pillar['netshares'][share]['mount'] }} cifs rw,credentials=/etc/.smbuser,uid=1000,gid=1000 0 0

{% endfor %}

/etc/.smbuser:
  file.managed:
    - user: root
    - group: root
    - mode: 0400
    - contents: | 
        domain=ICATU
        username=duda
        password={{ pillar['geroncio'] }}

systemctl daemon-reload:
  cmd.run

{% else %}
'-- not windows netshares defined': test.nop

{% endif %}
