#
# cria um arquivo de configuração sudo para que o administrador não precise usar senha 
# quando for gerenciar pacotes (insecure)
#

# read map with os_family dependent info
{% import_yaml "maps/users/by_os_family.yaml" as osf %}
{% set osf = salt.grains.filter_by(osf) %}

#
# tem que instalar o sudo em algumas imagens
sudo:
  pkg.installed

00-pkg_app_{{ osf.sudo_group }}:
  file.managed:
    - name: /etc/sudoers.d/00-pkg_app
    - makedirs: true
    - contents: |
        #
        ## Allow people in group {{ osf.sudo_group }} to run all commands (with password)
        %{{ osf.sudo_group }}  ALL=(ALL)   ALL

        #
        ## Allow people in group {{ osf.sudo_group }} to manage apps (without password)
        {% for pkg_app in osf.pkg_apps -%}
        %{{ osf.sudo_group }}  ALL=(ALL)   NOPASSWD: {{ pkg_app }}
        {% endfor %}

{% if not salt['grains.get']('flag_etc_sudoers_set', False) %} # if not appended yet
{% if grains['os_family'] == 'RedHat' %}
/etc/sudoers:
  file.append:
    - text: |
        
        # 
        ## root on sudoers so that I don't get reported
        root    ALL=(ALL)   ALL
        
        #
        ## Read drop-in files from /etc/sudoers.d (the # here does not mean a comment)
        #includedir /etc/sudoers.d
{% elif grains['os_family'] == 'Suse' %}
/etc/sudoers:
  file.managed:
    - source: salt://files/users/sudoers_suse
{% endif %}
flag_etc_sudoers_set:
  grains.present: 
    - value: True
    - require:
      - file: /etc/sudoers
{% endif %}
