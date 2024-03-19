#### CIS 5.5 User Accounts and Environment

### CIS 5.5.1 Set Shadow Password Suite Parameters

## CIS 5.5.1.1 Ensure minimum days between password changes is configured
'PASS_MIN_DAYS':
  file.replace:
    - name: /etc/login.defs
    - pattern: '^PASS_MIN_DAYS\t0$'
    - repl: 'PASS_MIN_DAYS 1'

'chage --mindays':
  cmd.script:
    - source: salt://cis-benchmark/scripts/chage_mindays.sh
    - cwd: /root

## CIS 5.5.1.2 Ensure password expiration is 365 days or less
'PASS_MAX_DAYS':
  file.replace:
    - name: /etc/login.defs
    - pattern: '^PASS_MAX_DAYS\t99999$'
    - repl: 'PASS_MAX_DAYS 365'

'chage --maxdays':
  cmd.script:
    - source: salt://cis-benchmark/scripts/chage_maxdays.sh
    - cwd: /root

## CIS 5.5.1.3 Ensure password expiration warning days is 7 or more
'PASS_WARN_AGE':
  file.replace:
    - name: /etc/login.defs
    - pattern: '^PASS_WARN_AGE\t0$'
    - repl: 'PASS_WARN_AGE 7'

'chage --warndays':
  cmd.script:
    - source: salt://cis-benchmark/scripts/chage_warndays.sh
    - cwd: /root

## CIS 5.5.1.4 Ensure inactive password lock is 30 days or less
useradd -D -f 30: cmd.run

'chage --inactive':
  cmd.script:
    - source: salt://cis-benchmark/scripts/chage_inactive.sh
    - cwd: /root

## CIS 5.5.1.5 Ensure all users last password change date is in the past
'-- check user pw age':
  cmd.script:
    - source: salt://cis-benchmark/scripts/check_pw_change.sh
    - cwd: /root

## CIS 5.5.3 Ensure default group for the root account is GID 0
'usermod -g 0 root':
  cmd.run:
    - unless: bash -c '[[ `grep "^root:" /etc/passwd | cut -f4 -d:` == 0 ]]'

## CIS 5.5.4 Ensure default user umask is 027 or more restrictive
'UMASK':
  file.replace:
    - name: /etc/login.defs
    - pattern: '^UMASK.*022$'
    - repl: 'UMASK 027'

'USERGROUPS_ENAB':
  file.replace:
    - name: /etc/login.defs
    - pattern: '^USERGROUPS_ENAB\s*yes$'
    - repl: 'USERGROUPS_ENAB no'

## CIS 5.5.5 Ensure default user shell timeout is 900 seconds or less
'/etc/profile':
  file.append:
    - text: |
          # adiciona tmout  se a sessão for originada de SSH ou TERM=linux (console direta)
          if [ ! -z "${SSH_TTY}" -o "${TERM}" == "linux" ]; then
              typeset -xr TMOUT=900
              export TMOUT
          fi

### CIS 6 System Maintenance
