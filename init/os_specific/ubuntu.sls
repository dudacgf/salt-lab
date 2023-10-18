#
## no phased updates 
'/etc/apt/apt.conf.d/80-PhasedUpdates':
  file.managed:
    - contents: 
      - '// Enable/Disable phased updates'
      - '// Default is Phased Updates enabled. Use these lines to disable.'
      - 'APT::Get::Never-Include-Phased-Updates: True;'
      - 'Update-Manager::Never-Include-Phased-Updates;'
      - 'APT::Get::Always-Include-Phased-Updates "1";'

#
## remove snapd em sistemas Ubuntu
{% if grains['os'] == 'Ubuntu' and grains['osmajorrelease'] > 20 and pillar['remove_snapd'] | default(False) %}
apt-get purge snapd -y:
  cmd.run
{% endif %}

