#
# cria um arquivo de configuração sudo para que o administrador não precise usar senha 
# quando for gerenciar pacotes (insecure)
#

#
# tem que instalar o sudo em algumas imagens
sudo:
  pkg.installed

#
# busca pgk_apps no pillar (pacotes instaladores de aplicação)
{% set grouplist = pillar.get('pkg_apps', 'sudo') %}

{% for groupname in grouplist %}
{% set pkg_apps = salt['pillar.get']('pkg_apps:' + groupname, {}) %}

00-pkg_app_{{ groupname }}:
  file.managed:
    - name: /etc/sudoers.d/00-pkg_app
    - makedirs: true
    - contents: |
        #
        ## Allow people in group {{ groupname }} to run all commands (with password)
        %{{ groupname }}  ALL=(ALL)   ALL

        #
        ## Allow people in group {{ groupname }} to manage apps (without password)
        {% for pkg_app in pkg_apps -%}
        %{{ groupname }}  ALL=(ALL)   NOPASSWD: {{ pkg_app }}
        {% endfor %}

{% endfor %}

{% if grains['os_family'] == 'RedHat' %}
{% if not salt['grains.get']('flag_etc_sudoers_set', False) %} # if not appended yet
/etc/sudoers:
  file.append:
    - text: |
        
        # 
        ## root on sudoers so that I don't get reported
        root    ALL=(ALL)   ALL
        
        #
        ## Read drop-in files from /etc/sudoers.d (the # here does not mean a comment)
        #includedir /etc/sudoers.d
flag_etc_sudoers_set:
  grains.present: 
    - value: ok
    - require:
      - file: /etc/sudoers
{% endif %}
{% endif %}
