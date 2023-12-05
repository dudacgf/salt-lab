# register a minion in aws route53 dns
{{ pillar['pkg_data']['awscli'] }}:
  pkg.installed

{{ sls }} copy aws files: 
  file.managed:
    - template: jinja
    - makedirs: True
    - user: root
    - group: root
    - mode: 600
    - names:
      - /root/.aws/credentials:
        - source: salt://files/secrets/aws-credentials.jinja
      - /root/.aws/config:
        - contents: |
            [default]

register host:
  cmd.script:
    - source: salt://files/scripts/aws-register.sh.jinja
    - template: jinja
    - shell: /bin/bash
    - require:
      - pkg: {{ pillar['pkg_data']['awscli'] }}
      - file: {{ sls }} copy aws files
{%- if pillar['proxy'] | default('none') != 'none' %}
    - env:
      - https_proxy: {{ pillar['proxy'] }}
      - http_proxy: {{ pillar['proxy'] }}
{%- endif %}

delete_secrets:
  cmd.run:
    - name: rm /root/.aws/credentials
    - require:
      - file: {{ sls }} copy aws files

