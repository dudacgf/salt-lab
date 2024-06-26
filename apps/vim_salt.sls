# install packages
#

{%- import_yaml "maps/pkg_data/" + grains.os_family | lower + ".yaml" as pkg_data %}

install vim-packages:
  pkg.installed:
    - pkgs: {{ pkg_data.vim.install_pkgs }}

{%- set users = ['duda', 'root'] %}

{%- for user in users %}
{%- set homedir = salt.user.info(user)['home'] %}
{{ user }} install pathogen:
  cmd.run:
     - name: 'mkdir -p {{ homedir }}/.vim/autoload {{ homedir }}/.vim/bundle && curl -LSso {{ homedir }}/.vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim'
     - unless:
       - 'ls -l {{ homedir }}/.vim/autoload/pathogen.vim'

{{ user }} chown .vim:
  cmd.run:
    - name: 'chown -R {{ user }} {{ homedir }}/.vim'

{{ user }} deploy vimrc:
  file.managed:
    - name: '{{ homedir }}/.vimrc'
    - source: salt://files/users/vimrc
    - user: {{ user }}
    - mode: 640

{{ user }} deploy runtime pathogen:
  file.managed:
    - name: '{{ homedir }}/.vim/pathogen'
    - user: {{ user }}
    - mode: 640
    - contents: |
        execute pathogen#infect()
        filetype plugin indent on

{{ user }} deploy salt-vim:
  git.latest: 
    - name: 'https://github.com/vmware-archive/salt-vim.git'
    - target: '{{ homedir }}/.vim/bundle/salt-vim'
    - user: {{ user }}

{{ user }} deploy jinja2-syntax:
  git.latest:
    - name: 'https://github.com/Glench/Vim-Jinja2-Syntax.git'
    - target: '{{ homedir }}/.vim/bundle/jinja2'
    - user: {{ user }}
{%- endfor %}
