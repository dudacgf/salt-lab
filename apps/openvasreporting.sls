#!jinja|yaml
#
## openvasreporting.sls - instala o módulo de mesmo nome em um mínion para criação 
#      de relatórios

# install prereqs
{% if grains['os_family'] == 'RedHat' %}
instala básicos:
  pkg.installed:
    - pkgs: ['python3', 'python3-wheel', 'git']
{% elif grains['os_family'] == 'Debian' %}
instala básicos:
  pkg.installed:
    - pkgs: ['python3', 'python3-pip', 'python3-venv', 'python3-wheels', 'git']
{% endif %}

# clone openvasreporting repo
git openvasreporting repo cloning:
  git.latest:
    - name: 'https://github.com/TheGroundZero/openvasreporting'
    - target: '/root/openvasreporting'

# can't use pip.installed after 3006.x because it would install openvasreporting
# under salt-pip and not global pip
build openvasreporting:
  cmd.run:
    - name: python3 -m build
    - cwd: /root/openvasreporting

install openvasreporting:
  cmd.run:
    - name: pip3 install .
    - cwd: /root/openvasreporting


