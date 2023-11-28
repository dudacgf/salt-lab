{% if grains.os_family == 'Debian' %}
install cinnamon: 
  pkg.installed:
    - name: task-cinnamon-desktop

{% else %}
'=== OS Not Supported. Cinnamon will not be installed ===':
  test.fail_without_changes:
    - failhard: True
{% endif %}


{% for user in salt.lusers.sys_accounts() | difference(['root']) %}
/var/lib/AccountSettings/user/{{ user }}:
  file.managed:
    - user: root
    - group: root
    - mode: 0644
    - contents: |
         [User]
         Session=
         Icon=/var/lib/lightdm/.face
         SystemAccount=true
    - require:
      - install cinnamon
{% endfor %}

systemctl reboot:
  cmd.run:
    - require:
      - install cinnamon

