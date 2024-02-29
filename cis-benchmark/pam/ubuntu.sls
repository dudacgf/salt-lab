## CIS 5.4.1 Ensure password creation requirements are configured
{% if grains['os_family'] == 'Debian' %}
libpam-pwquality: pkg.installed
{% endif %}

/etc/pam.d/pwquality.conf:
  file.managed:
    - contents: | 
          minlen = 14
          minclass = 4
          dcredit = -1
          ucredit = -1
          ocredit = -1
          lcredit = -1

## CIS 5.4.2 Ensure lockout for failed password attempts is configured
/etc/pam.d/common-auth:
  file.line:
    - mode: insert
    - after: '# pam-auth-update(8) for details.'
    - before: '# here are the per-package modules \(the "Primary" block\)'
    - content: |
          auth required pam_faillock.so preauth # Added to enable faillock
          auth [success=1 default=ignore] pam_unix.so nullok
          auth [default=die] pam_faillock.so authfail # Added to enable faillock
          auth sufficient pam_faillock.so authsucc # Added to enable faillock
    - unless: "grep 'auth sufficient pam_faillock.so authsucc' /etc/pam.d/common-auth"

/etc/pam.d/common-account:
  file.append:
    - text: account required pam_faillock.so

/etc/security/faillock.conf:
  file.managed:
    - contents: |
          deny = 4
          fail_interval = 900
          unlock_time = 600

## CIS 5.4.3 Ensure password reuse is limited 
/etc/pam.d/common-password:
  file.replace:
    - pattern: '^password    [success=1 default=ignore]  pam_unix.so obscure yescrypt$'
    - repl: 'password [success=1 default=ignore] pam_unix.so obscure use_authtok try_first_pass remember=5'

## CIS 5.4.4 Ensure password hashing algorithm is up to date with the latest standards
/etc/login.defs:
  file.replace:
    - pattern: '^ENCRIPT_METHOD .*$'
    - repl: 'ENCRYPT_METHOD yescript'

## CIS 5.4.5 Ensure all current passwords uses the configured hashing algorithm
'-- running check password algo script':
  cmd.script:
    - source: salt://cis-benchmark/scripts/check_pw_hash.sh
    - cwd: /root

## CIS 5.5.4 load pam_umask.sh
## ALREADY THERE ON /etc/pam.d/common-session
## session optional pam_umask.so


