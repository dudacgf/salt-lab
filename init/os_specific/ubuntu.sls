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
## adds a local repo if running in a libvirt
{% if grains.virtual | default('none') == 'kvm' %}
/etc/apt/sources.list.d/ubuntu-iso.list:
  file.managed:
    - contents: |
        deb http://10.1.115.1/ubuntu-iso/ jammy main
{% endif %}

#
## remove snapd em sistemas Ubuntu
{% if grains['os'] == 'Ubuntu' and grains['osmajorrelease'] > 20 and pillar['remove_snapd'] | default(False) %}
apt-get purge snapd -y:
  cmd.run
{% endif %}

