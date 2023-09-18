#
## roles/graylog.sls - instala mongodb, elasticsearch e graylog. costura a configuração entre graylog e os outros
# 

include:
  - linux_services.mongodb
  - linux_services.elasticsearch
  - linux_services.kibana
  - linux_services.graylog


