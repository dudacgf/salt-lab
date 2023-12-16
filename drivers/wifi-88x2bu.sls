# install prerequisites
{% if grains['os_family'] == 'Debian' %}
install 88x2bu pre-reqs:
  pkg.installed:
    - pkgs: ['linux-headers-{{ grains["kernelrelease"] }}', 'build-essential', 'bc', 'dkms', 'git', 'libelf-dev', 'rfkill', 'iw']

{% elif grains['os_family'] == 'RedHat' %} 
install 88x2bu pre-reqs:
  pkg.installed:
    - pkgs: ['dkms', 'gcc', 'bc', 'git', 'iw']

{% else %}
install 88x2bu pre-reqs:
  test.fail_without_changes
    - comment: '=== OS not supported. driver 88x2bu will not be installed ==='
    - result: false

{% endif %}
# 
'/root/src': 
  file.directory:
    - require:
      - install 88x2bu pre-reqs

# download source
'https://github.com/morrownr/88x2bu-20210702.git':
  git.cloned:
    - target: /root/src/88x2bu
    - require: 
      - file: '/root/src'

# install the driver
install driver 88x2bu:
  cmd.run:
    - name: '/root/src/88x2bu/install-driver.sh NoPrompt'
    - cwd: /root/src/88x2bu
    - ignore_timeout: True
    - require:
      - git: 'https://github.com/morrownr/88x2bu-20210702.git'

# load the driver
modprobe 88x2bu:
  cmd.run:
    - require:
      - cmd: install driver 88x2bu

88x2bu toggle flag_driver_installed on:
  grains.present:
    - name: flag_driver_installed
    - value: True
    - require:
      - cmd: install driver 88x2bu

'-- driver 88x2bu installed':
  test.nop:
    - require:
      - cmd: install driver 88x2bu

'-- driver 88x2bu not installed':
  test.nop:
    - onfail:
      - cmd: install driver 88x2bu
