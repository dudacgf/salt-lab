#
## lamp.sls - instala apache, mysql (mariadb) e php
#

include:
  - linux_services.apache
  - linux_services.mariadb
  - linux_services.php


