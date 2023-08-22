#
## debian.sls - configurações específicas para os_family 'Debian'
#

'/etc/apt/apt.conf.d/80-PhasedUpdates':
  file.managed:
    - contents: 
      - '// Enable/Disable phased updates'
      - '// Default is Phased Updates enabled. Use these lines to disable.'
      - 'APT::Get::Never-Include-Phased-Updates: True;'
      - 'Update-Manager::Never-Include-Phased-Updates;'
      - 'APT::Get::Always-Include-Phased-Updates "1";'

{% if pillar['install_nonfree'] | default(True) %}
'/etc/apt/sources.list.d/debian_extras.list':
  file.managed:
    - contents: [
      'deb http://alcateia.ufscar.br/debian/ {{ grains['oscodename'] }} contrib',
      'deb-src http://alcateia.ufscar.br/debian/ {{ grains['oscodename'] }} contrib',
      'deb http://alcateia.ufscar.br/debian/ {{ grains['oscodename'] }} non-free',
      'deb-src http://alcateia.ufscar.br/debian/ {{ grains['oscodename'] }} non-free',
      ]

firmware-linux-nonfree:
  pkg.installed

firmware-intel-sound:
  pkg.installed

firmware-realtek:
  pkg.installed

{% endif %}

