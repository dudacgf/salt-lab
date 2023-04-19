#
## windows_servers.sls - define os papéis de cada servidor
#
## (c) ecgf - junho/2021
servers:
  ESTACAO044:
    location: LBL1100
    isactivedirectory: false
    isfileserver: true
    isterminalserver: true
    tags: fileserver
    

