###
### CIS 5.4 AUTHSELECT
###

## CIS 5.4.1  Ensure custom authselect profile is used
{% if salt.cmd.shell('authselect list | grep -c custom/cis-profile') == '0' %}
'authselect create-profile cis-profile -b minimal --symlink-meta': cmd.run
{% endif %}

## CIS 
'authselect select --force custom/cis-profile with-faillock without-nullok with-pwhistory': cmd.run

###
### CIS 5.5 Configure PAM
###

## CIS 5.5.1 Ensure password creation requirements are configured
{% if grains['os_family'] == 'Debian' %}
libpam-pwquality: pkg.installed
{% endif %}

/etc/security/pwquality.conf:
  file.managed:
    - contents: | 
          minlen = 14
          minclass = 4
          dcredit = -1
          ucredit = -1
          ocredit = -1
          lcredit = -1
          retry = 3

/etc/security/pwhistory.conf:
  file.managed:
    - contents: |
          debug
          enforce_for_root
          remember = 5
          retry = 1
          file = /etc/security/opasswd

password-auth pwquality:
  file.replace:
    - name: /etc/authselect/custom/cis-profile/password-auth
    - pattern: '^password(\s+)requisite(\s+)pam_pwquality.so$'
    - repl: 'password\1requisite\2pam_pwquality.so retry=3'

system-auth pwquality:
  file.replace:
    - name: /etc/authselect/custom/cis-profile/system-auth
    - pattern: '^password(\s+)requisite(\s+)pam_pwquality.so$'
    - repl: 'password\1requisite\2pam_pwquality.so retry=3'

pwhistory:
  file.replace:
    - name: /etc/authselect/custom/cis-profile/password-auth
    - pattern: '^password(\s+)requisite(\s+)pam_pwhistory.so use_authtok(\s+)(.*)$'
    - repl: 'password\1requisite\2pam_pwhistory.so use_authtok remember=5\3\4'

## remove nullok from password-auth and system-auth
password-auth nullok:
  file.replace:
    - name: /etc/authselect/custom/cis-profile/password-auth
    - pattern: ' nullok'
    - repl: ''

system-auth nullok:
  file.replace:
    - name: /etc/authselect/custom/cis-profile/system-auth
    - pattern: ' nullok'
    - repl: ''

## CIS 5.5.2 Ensure lockout for failed password attempts is configured
authselect-compat: pkg.installed

/etc/security/faillock.conf:
  file.managed:
    - contents: |
          deny = 3
          fail_interval = 900
          unlock_time = 900

'authconfig --enablefaillock --faillockargs="deny=3 fail_interval=900 unlock_time=900" --update': cmd.run

/etc/authselect/custom/cis-profile/system-auth:
  file.line:
    - after: '^auth\s+required\s+pam_deny.so'
    - before: '^account\s+required\s+pam_access.so.*$'
    - mode: insert
    - content: |
          auth   required      pam_faillock.so preauth silent audit deny=3 fail_interval=900 unlock_time=900
          auth   [default=die] pam_faillock.so authfail audit deny=3 fail_interval=900 unlock_time=900

/etc/authselect/custom/cis-profile/password-auth:
  file.line:
    - after: '^auth\s+required\s+pam_deny.so'
    - before: '^account\s+required\s+pam_access.so.*$'
    - mode: insert
    - content: |
          auth   required      pam_faillock.so preauth silent audit deny=3 fail_interval=900 unlock_time=900
          auth   [default=die] pam_faillock.so authfail audit deny=3 fail_interval=900 unlock_time=900

authselect apply-changes:
  cmd.run:
    - require:
      - file: /etc/authselect/custom/cis-profile/password-auth
      - file: /etc/authselect/custom/cis-profile/system-auth

## CIS 5.5.3 Ensure password reuse is limited 
#old_pw_remember:
#  cmd.script:
#    - source: salt://cis-benchmark/scripts/old_pw_remember.sh
#    - cwd: /root
#
#'authselect enable-feature with-pwhistory': cmd.run

## CIS 5.5.4 Ensure password hashing algorithm is SHA-512 or yescrypt
## ALREADY SHA-512
#/etc/login.defs:
#  file.replace:
#    - pattern: '^ENCRIPT_METHOD .*$'
#    - repl: 'ENCRYPT_METHOD yescript'


