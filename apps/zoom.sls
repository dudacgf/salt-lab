#
### zoom.sls - install zoom on a minion

install zoom:
  pkg.installed:
    - update:  True
    - refresh: True
    - sources:
      - zoom: https://zoom.us/client/latest/zoom_amd64.deb

