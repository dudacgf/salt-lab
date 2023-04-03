#!/bin/bash
#
## mysql_create_db_user - cria usuário, database e grants do database para o usuário
#

if [[ -z ${1} || -z ${2} || -z {3} || -z ${4} ]]; then
  echo 'usage: ${0} mariadb_root_pw db_name db_user db_password'
  exit 1;
fi;

mariadb_root_pw=${1}
db_name=${2}
db_user=${3}
db_password=${4}

mysql --user=root --password=${mariadb_root_pw} <<_EOF_
create user if not exists '${db_user}'@'localhost' identified by '${db_password}';
create database if not exists ${db_name} default charset = utf8mb4 default collate = utf8mb4_unicode_ci;
grant all on ${db_name}.* to '${db_user}'@'localhost';
flush privileges;
_EOF_

