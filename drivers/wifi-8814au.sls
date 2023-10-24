#!jinja|yaml

{% if grains['os_family'] != 'RedHat' %}

# install prerequisites
install 8814au pre-reqs:
  pkg.installed:
    - pkgs: ['linux-headers-{{ grains["kernelrelease"] }}', 'build-essential', 'bc', 'dkms', 'git', 'libelf-dev', 'rfkill', 'iw']

# 
'/root/src':
  file.directory

# download source
'https://github.com/morrownr/8814au.git':
  git.cloned:
    - target: /root/src/8814au
    - require: 
      - pkg: install 8814au pre-reqs
      - file: '/root/src'

# install the driver
'/root/src/8814au/install-driver.sh':
  cmd.run:
    - cwd: /root/src/8814au
    - args: ['NoPrompt']
    - require:
      - git: 'https://github.com/morrownr/8814au.git'

reboot 8814au:
  cmd.run:
    - name: /bin/bash -c 'sleep 5; shutdown -r now'
    - bg: True
    - require:
      - cmd: '/root/src/8814au/install-driver.sh'

{% else %}

'-- won\'t install in redhat derivatives':
  test.nop

8814au send start event anyway:
  cmd.run:
    - name: /bin/bash -c "sleep 5; salt-call event.send 'salt/minion/{{ grains['id'] }}/start'"
    - bg: True
{% endif %}
