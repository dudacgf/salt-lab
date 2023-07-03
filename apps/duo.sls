{% if grains['os'] == 'Ubuntu' %}
add duo repo:
  pkgrepo.managed:
    - name: deb [arch=amd64] https://pkg.duosecurity.com/Ubuntu jammy main
    - humanname: Duo Security Repository
    - file: /etc/apt/sources.list.d/duo.list
    - key_url: https://duo.com/DUO-GPG-PUBLIC-KEY.asc
{% elif grains['os'] == 'Debian' %}
add duo repo:
  pkgrepo.managed:
    - name: deb [arch=amd64] https://pkg.duosecurity.com/Debian bullseye main
    - humanname: Duo Security Repository
    - file: /etc/apt/sources.list.d/duo.list
    - key_url: https://duo.com/DUO-GPG-PUBLIC-KEY.asc
{% elif grains['os_family'] == 'RedHat' %}
add duo repo:
  pkgrepo.managed:
    - name: Duo Security Repository
    - enabled: True
    - baseurl: https://pkg.duosecurity.com/RedHat/9/x86_64
    - gpgcheck: 1
    - gpgkey: https://duo.com/DUO-GPG-PUBLIC-KEY.asc
    - file: /etc/yum.repos.d/duo.repo
{% else %}
failure:
  test.fail_without_changes:
    - text: '*** elasticsearch: OS not supported. Will not install ***'
    - failhard: True
{% endif %}

{{ pillar['pkg_data']['duo']['name'] }}:
  pkg.installed:
    - require:
      - pkgrepo: add duo repo

/etc/duo/pam_duo.conf:
  file.managed:
    - contents: |
        [duo]
        ikey = {{ pillar['duo']['ikey'] }}
        skey = {{ pillar['duo']['skey'] }}
        host = {{ pillar['duo']['host'] }}
        failmode = safe
        pushinfo = yes
        groups = users,!scanacct

/etc/duo/login_duo.conf:
  file.managed:
    - contents: |
        [duo]
        ikey = {{ pillar['duo']['ikey'] }}
        skey = {{ pillar['duo']['skey'] }}
        host = {{ pillar['duo']['host'] }}
        failmode = safe
        pushinfo = yes
        groups = users,!scanacct

Auth Methods:
  file.line:
      - name: /etc/ssh/sshd_config
      - mode: insert
      - after: '^PasswordAuthentication no #'
      - content: 'AuthenticationMethods publickey,keyboard-interactive'

Chalng Auth:
  file.replace:
      - name: /etc/ssh/sshd_config
      - pattern: '^ChallengeResponseAuthentication no'
      - repl: 'ChallengeResponseAuthentication yes'

{% if grains['os_family'] == 'RedHat' and grains['osmajorrelease'] == 9 %}
/etc/ssh/sshd_config.d/50-redhat.conf:
  file.line:
    - match: '^ChallengeResponseAuthentication no'
    - mode: delete

duo system auth:
  file.replace:
    - name: /etc/pam.d/system-auth
    - pattern: '^auth.*sufficient.*pam_unix.so.*$'
    - repl: |
        auth        requisite      pam_unix.so try_first_pass nullok
        auth        sufficient     pam_duo.so

/etc/pam.d/sshd:
  file.replace:
    - pattern: '^auth.*substack.*password-auth'
    - repl: |
        auth       required       pam_sepermit.so
        auth       required       pam_env.so
        auth       sufficient     pam_duo.so
        auth       required       pam_deny.so

/etc/pam.d/sudo:
  file.replace:
    - pattern: '^auth.*include.*system-auth'
    - repl: |
        auth required pam_env.so
        auth requisite pam_unix.so
        auth sufficient pam_duo.so
        auth required pam_deny.so

{% elif grains['os_family'] == 'Debian' %}
/etc/pam.d/common-auth:
  file.replace:
    - pattern: '^auth.*\[success=1.*nullok_secure$'
    - repl: |
        auth  requisite pam_unix.so nullok_secure
        auth  [success=1 default=ignore] /usr/lib64/security/pam_duo.so

/etc/pam.d/sshd:
  file.replace:
    - pattern: '^@include common-auth$'
    - repl: |
        auth  [success=1 default=ignore] /usr/lib64/security/pam_duo.so
        auth  requisite pam_deny.so
        auth  required pam_permit.so

/etc/pam.d/sudo:
{%- if grains['os'] == 'Debian' %}
{%- set pattern = '@include common-auth' %}
{%- elif grains['os'] == 'Ubuntu' %}
{%- set pattern = 'session    required   pam_limits.so' %}
{%- endif %}
  file.replace:
    - pattern: '^{{ pattern }}$'
    - repl: |
        {{ pattern }}  ## replaced
        auth       required   pam_env.so
        auth       requisite  pam_unix.so
        auth       sufficient /usr/lib64/security/pam_duo.so
        auth       required   pam_deny.so

{% if salt['file.file_exists']('/etc/pam.d/gdm-password') | default(False) %}
/etc/pam.d/gdm-password:
  file.replace:
    - pattern: 'auth.*required.*pam_succeed_if.so user != root quiet_success$'
    - repl: |
        auth       required      pam_succeed_if.so user != root quiet_success ## replaced
        auth       requisite     pam_unix.so nullok_secure
        auth       sufficient    /lib64/security/pam_duo.so
        auth       requisite     pam_deny.so
{% endif %}

{% endif %}

sshd.service:
  service.running:
    - restart: true
    - watch: 
      - file: /etc/ssh/sshd_config
      - file: /etc/duo/pam_duo.conf
