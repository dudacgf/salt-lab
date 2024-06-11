rm -rf /var/lib/builder/source/*:
  cmd.run

/usr/local/bin/greenbone-feed-sync: 
  cmd.run:
    - require: 
      - cmd: rm -rf /var/lib/builder/source/*

start enable services:
  service.running:
    - names: 
      - ospd-openvas.service
      - gvmd.service
      - gsad.service
      - openvasd.service
      - notus-scanner.service
    - enable: True

