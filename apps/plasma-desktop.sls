{% if grains.os_family == 'RedHat' %}
install kde:
  cmd.run:
    - name: 'dnf groupinstall "KDE Plasma Workspaces" -y'

systemctl enable sddm.service:
  cmd.run:
    - require:
      - cmd: install kde

systemctl set-default graphical.target: 
  cmd.run:
    - require:
      - cmd: install kde

{% elif grains.os_family == 'Debian' %}
install kde: 
  pkg.installed:
    - name: 'kde-plasma-desktop'

{% else %}
'=== OS Not Supported. Plasma will not be installed ===':
  test.fail_without_changes:
    - failhard: True
{% endif %}

/etc/sddm.conf.d/kde_settings.conf:
  file.managed:
    - source: salt://files/apps/kde_settings.conf
    - template: jinja
    - makedirs: True
    - user: root
    - group: root
    - mode: 0644
    - require:
      - install kde

