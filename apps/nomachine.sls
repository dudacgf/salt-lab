{% if grains['os_family'] == 'Debian' %}
/tmp/nomachine.deb:
  file.managed:
    - source: https://download.nomachine.com/download/8.5/Linux/nomachine_8.5.3_1_amd64.deb
    - skip_verify: True
    - verify_ssl: False

instala nomachine:
  cmd.run:
    - name: dpkg -i /tmp/nomachine.deb 
    - require: 
      - file: /tmp/nomachine.deb

{% elif grains['os_family'] == 'RedHat' %}

python packages:
  pkg.installed:
    - pkgs: [ 'python3-pycurl', 'python3-tornado']

/tmp/nomachine.rpm:
  file.managed:
    - source: https://download.nomachine.com/download/8.5/Linux/nomachine_8.5.3_1_x86_64.rpm
    - skip_verify: True

instala nomachine:
  cmd.run:
    - name: dnf install /tmp/nomachine.rpm -y
    - require: 
      - file: /tmp/nomachine.rpm

{% else %}

'-- OS not supported: {{ grains['os_family'] }}':
  test.nop

{% endif %}
