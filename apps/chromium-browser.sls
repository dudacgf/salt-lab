install_chromium:
  pkgrepo.managed:
    - ppa: xtradeb/apps
  pkg.latest:
    - name: chromium
    - refresh: True

