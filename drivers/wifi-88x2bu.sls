{% if grains['os_family'] != 'RedHat' %}

# install prerequisites
install 88x2bu pre-reqs:
  pkg.installed:
    - pkgs: ['linux-headers-{{ grains["kernelrelease"] }}', 'build-essential', 'bc', 'dkms', 'git', 'libelf-dev', 'rfkill', 'iw']

# 
'/root/src': file.directory

# download source
'https://github.com/RinCat/RTL88x2BU-Linux-Driver.git':
  git.cloned:
    - target: /root/src/88x2bu
    - require: 
      - pkg: install 88x2bu pre-reqs
      - file: '/root/src'

# copy install script (adapted from https://github.com/morrownr/8814au.git)
'/root/src/88x2bu/install-driver.sh':
  file.managed:
    - source: 'salt://files/scripts/88x2bu-install-driver.sh'
    - mode: 755
    - require:
      - git: 'https://github.com/RinCat/RTL88x2BU-Linux-Driver.git'

# install the driver
install driver 88x2bu:
  cmd.run:
    - name: '/root/src/88x2bu/install-driver.sh NoPrompt'
    - cwd: /root/src/88x2bu
    - require:
      - file: '/root/src/88x2bu/install-driver.sh'

88x2bu toggle flag_driver_installed on:
  grains.present:
    - name: flag_driver_installed
    - value: True
    - require:
      - cmd: install driver 88x2bu

'-- driver 88x2bu installed':
  test.nop
    - require:
      - cmd: install driver 88x2bu

'-- driver 8814au not installed':
  test.nop:
    - onfail:
      - cmd: install driver 88x2bu

{% else %}

'-- won\'t install in redhat derivatives':
  test.nop

88x2bu send start event anyway:
  cmd.run:
    - name: /bin/bash -c "sleep 5; salt-call event.send 'salt/minion/{{ grains['id'] }}/start'"
    - bg: True
{% endif %}
