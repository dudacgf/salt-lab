# install prerequisites
{% if grains['os_family'] == 'Debian' %}
install 8814au pre-reqs:
  pkg.installed:
    - pkgs: ['linux-headers-{{ grains["kernelrelease"] }}', 'build-essential', 'bc', 'dkms', 'git', 'libelf-dev', 'rfkill', 'iw']

{% elif grains['os_family'] == 'RedHat' %} 
install 8814au pre-reqs:
  pkg.installed:
    - pkgs: ['dkms', 'gcc', 'bc', 'git', 'iw']

{% else %}
install 8814au pre-reqs:
  test.fail_without_changes
    - comment: '=== OS not supported. driver 8814au will not be installed ==='
    - result: false

{% endif %}
# 
'/root/src': 
  file.directory:
    - require:
      - install 8814au pre-reqs

# download source
'https://github.com/morrownr/8814au.git':
  git.cloned:
    - target: /root/src/8814au
    - require: 
      - file: '/root/src'

# install the driver
install driver 8814au:
  cmd.run:
    - name: '/root/src/8814au/install-driver.sh NoPrompt'
    - cwd: /root/src/8814au
    - require:
      - git: 'https://github.com/morrownr/8814au.git'

8814au toggle flag_driver_installed on:
  grains.present:
    - name: flag_driver_installed
    - value: True
    - require:
      - cmd: install driver 8814au

'-- driver 8814au installed':
  test.nop:
    - require:
      - cmd: install driver 8814au

'-- driver 8814au not installed':
  test.nop:
    - onfail:
      - cmd: install driver 8814au
