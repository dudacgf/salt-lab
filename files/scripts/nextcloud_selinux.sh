#!/bin/bash

# permite rw em alguns diretórios do nextcloud
semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/nextcloud/data(/.*)?'
semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/nextcloud/config(/.*)?'
semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/nextcloud/apps(/.*)?'
semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/nextcloud/.htaccess'
semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/nextcloud/.user.ini'
semanage fcontext -a -t httpd_sys_rw_content_t '/var/www/nextcloud/3rdparty/aws/aws-sdk-php/src/data/logs(/.*)?'

restorecon -Rv '/var/www/nextcloud/'

# permite updates via interface
setsebool httpd_unified on

# permite acesso a db remoto
setsebool -P httpd_can_network_connect_db on

# permite acesso ao servidor LDAP
setsebool -P httpd_can_connect_ldap on

# permite acesso a rede remota (compartilhamento, external files, app store etc)
setsebool -P httpd_can_network_connect on

# permite acesso a memcache remoto
setsebool -P httpd_can_network_memcache on

# permite envio de mail
setsebool -P httpd_can_sendmail on

# permite acesso a cifs/smb shares:
setsebool -P httpd_use_cifs on

# permite acesso a FuseFS
setsebool -P httpd_use_fusefs on

# permite acesso a GPG para Rainloop
setsebool -P httpd_use_gpg on

