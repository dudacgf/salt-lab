/tmp/create_bond.sh:
  file.managed:
    - source: salt://files/scripts/create-bond.sh.jinja
    - template: jinja
    - user: duda
    - group: duda
    - mode: 755

