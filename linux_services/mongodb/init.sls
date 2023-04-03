
include:
  - .install
  - .configure
  - .accesscontrol
  - .selinux
  
# 
# ajusta o serviço mongodb
mongod.service:
  service.running:
    - enable: true
 
