{%- if grains['os_family'] == 'RedHat' and pillar['selinux_mode'] | default('enforcing') == 'enforcing' and not pillar['flag_mongodb_selinux_policy_set'] | default(False) %}
/tmp/mongodb_selinux.pp:
  file.managed:
    - name: /tmp/mongodb_selinux.pp
    - source: salt://files/selinux/mongodb_selinux.pp

mongod selinux:
  cmd.run:
    - name: semodule -i /tmp/mongodb_selinux.pp
    - require:
      - file: /tmp/mongodb_selinux.pp

flag_mongodb_selinux_policy_set:
  grains.present:
    - value: True
{%- endif %}

