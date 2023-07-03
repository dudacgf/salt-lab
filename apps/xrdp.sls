xrdp:
  pkg.installed

xrdp.service:
  service.running:
    - enable: True

public:
  firewalld.present:
    - ports: [ '3389/tcp' ]
    - sources: [ 10.1.115.1, 10.1.16.221, 10.1.26.38 ]

