copia godaddy files:
  file.managed:
    - names:
      - /root/godaddy_secrets:
        - source: salt://files/secrets/godaddy_config.jinja
        - mode: 400
      - /root/godaddy_ddns.py:
        - source: salt://files/scripts/godaddy_ddns.py
        - mode: 500
    - template: jinja
    - user: root
    - mode: root

register host:
  cmd.run:
    - name: 'python3 /root/godaddy_ddns.py %/root/godaddy_secrets'

delete_secrets:
  cmd.run:
    - name: rm /root/godaddy_secrets
    - require: 
      - file: copia godaddy files

