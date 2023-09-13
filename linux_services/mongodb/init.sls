
include:
  - .install
  - .configure
  - .accesscontrol
  - .selinux
  
#
# 'Failed to get properties: Access denied' error
systemctl daemon-reexec:
  cmd.run

# 
# ajusta o serviço mongodb
service.restart:
  module.run:
    - m_name: mongod.service
 
