download rambox:
  file.managed:
    - name: /tmp/rambox.deb
    - source: https://rambox.app/api/download?os=linux&package=deb
    - skip_verify: True

apt install /tmp/rambox.deb -y:
  cmd.run
