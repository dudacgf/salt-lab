###########
## DEBIAN 12 - THIS APPEARS AT 1.6
## UBUNTU 22.04 - THIS APPEARS AT 1.7
## REDHAT 9 - THIS APPEARS AT 1.7
##########

### 1.7 Command Line Warning Banners
## 1.7.1 Ensure message of the day is configured properly (remove it)
## 1.7.4 Ensure permissions on /etc/motd are configured
/etc/motd: file.absent

## 1.7.2 Ensure local login warning banner is configured properly 
## 1.7.5 Ensure permissions on /etc/issue are configured
/etc/issue: 
  file.managed:
    - user: root
    - group: root
    - mode: 0644
    - contents: | 
          --                                                                        --
          -- Apenas uso autorizado. Toda atividade pode ser monitorada e reportada. --
          --                                                                        --
          --    Authorized uses only. All activity may be monitored and reported.   --
          --                                                                        --
          --           I've read & consent to terms in IS user agreem't             --
          --                                                                        --

## 1.7.3 Ensure remote login warning banner is configured properly
## 1.7.6 Ensure permissions on /etc/issue.net are configured
/etc/issue.net: 
  file.managed:
    - user: root
    - group: root
    - mode: 0644
    - contents: | 
          --                                                                        --
          -- Apenas uso autorizado. Toda atividade pode ser monitorada e reportada. --
          --                                                                        --
          --    Authorized uses only. All activity may be monitored and reported.   --
          --                                                                        --
          --           I've read & consent to terms in IS user agreem't             --
          --                                                                        --

