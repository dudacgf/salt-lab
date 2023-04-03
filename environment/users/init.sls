##
#
## users.sls - cria/ajusta ambiente para usuários 
#
## (c) ecgf - Jun/2021
# 
##

#
# checa se o flag para gerenciamento de usuários está ligado
{% if salt['pillar.get']('manage_users', False) %}

include:
  - environment.users.users_manage
  - environment.users.root_manage
  - environment.users.sudo_manage

{% endif %}
