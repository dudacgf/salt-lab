#
# Adiciona o repositório do mongodb
#install_repo_key:
#  cmd.run:
#    - name: https_proxy=http://10.1.111.1:3128 wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | gpg --dearmor > /usr/share/keyrings/mongodb-archive-keyring.gpg
#    - creates: /usr/share/keyrings/mongodb-archive-keyring.gpg

mongodb:
  pkgrepo.managed:
    - name: deb http://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse
    - humanname: MongoDB repository 4.4 version
    - file: /etc/apt/sources.list.d/mongodb.list
    - key_url: salt://files/env/GPG-KEY-mongodb

