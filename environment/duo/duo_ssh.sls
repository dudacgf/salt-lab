{%- if pillar['duo']['ssh'] | default(False) %}
ssh Auth Methods:
  file.line:
      - name: /etc/ssh/sshd_config
      - mode: insert
      - after: '^PasswordAuthentication no #'
      - content: 'AuthenticationMethods publickey,keyboard-interactive'

ssh Chalng Auth:
  file.replace:
      - name: /etc/ssh/sshd_config
      - pattern: '^ChallengeResponseAuthentication no'
      - repl: 'ChallengeResponseAuthentication yes'

{% if grains['os_family'] == 'RedHat' and grains['osmajorrelease'] == 9 %}
/etc/ssh/sshd_config.d/50-redhat.conf:
  file.line:
    - match: '^ChallengeResponseAuthentication no'
    - mode: delete

/etc/pam.d/sshd:
  file.replace:
    - pattern: '^auth.*substack.*password-auth'
    - repl: |
        auth       required       pam_sepermit.so
        auth       required       pam_env.so
        auth       sufficient     pam_duo.so
        auth       required       pam_deny.so

{% elif grains['os_family'] == 'Debian' %}
/etc/pam.d/sshd:
  file.replace:
    - pattern: '^@include common-auth$'
    - repl: |
        auth  [success=1 default=ignore] /usr/lib64/security/pam_duo.so
        auth  requisite pam_deny.so
        auth  required pam_permit.so

{% endif %}

sshd.service:
  service.running:
    - restart: true
    - watch: 
      - file: /etc/ssh/sshd_config

{%- endif %} # if pillar['duo']['ssh']
