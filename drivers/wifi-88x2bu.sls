#!jinja|yaml

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
'/root/src/88x2bu/install-driver.sh':
  cmd.run:
    - cwd: /root/src/88x2bu
    - args: ['NoPrompt']
    - require:
      - file: '/root/src/88x2bu/install-driver.sh'

reboot 88x2bu:
  cmd.run:
    - name: /bin/bash -c 'sleep 5; shutdown -r now'
    - bg: True
    - require:
      - cmd: '/root/src/88x2bu/install-driver.sh'


'-- driver 88x2bu installed. will boot now':
  test.nop

{% else %}

'-- won\'t install in redhat derivatives':
  test.nop

88x2bu send start event anyway:
  cmd.run:
    - name: /bin/bash -c "sleep 5; salt-call event.send 'salt/minion/{{ grains['id'] }}/start'"
    - bg: True
{% endif %}
