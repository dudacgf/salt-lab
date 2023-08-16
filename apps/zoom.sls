#
### zoom.sls - install zoom on a minion

install zoom:
  pkg.installed:
    - sources:
      - zoom: https://zoom.us/client/latest/zoom_amd64.deb

