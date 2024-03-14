## CIS 6.1.1 Ensure permissions on /etc/passwd are configured
## CIS 6.1.2 Ensure permissions on /etc/passwd- are configured
## CIS 6.1.3 Ensure permissions on /etc/group are configured
## CIS 6.1.4 Ensure permissions on /etc/group- are configured
## CIS 6.1.5 Ensure permissions on /etc/shadow are configured
## CIS 6.1.6 Ensure permissions on /etc/shadow- are configured
## CIS 6.1.7 Ensure permissions on /etc/gshadow- are configured
## CIS 6.1.8 Ensure permissions on /etc/gshadow- are configured
{% set shadow_perms = salt.grains.filter_by({'Debian': '0640', 'RedHat': '0000'}) %}
adjust permissions:
  file.managed:
    - names:
      - /etc/password:
        - mode: 0644
        - user: root
        - group: root
      - /etc/password-:
        - mode: 0644
        - user: root
        - group: root
      - /etc/group:
        - mode: 0644
        - user: root
        - group: root
      - /etc/group-:
        - mode: 0644
        - user: root
        - group: root
      - /etc/shadow:
        - mode: {{ shadow_perms }}
        - user: root
        - group: root
      - /etc/shadow-:
        - mode: {{ shadow_perms }}
        - user: root
        - group: root
      - /etc/gshadow:
        - mode: {{ shadow_perms }}
        - user: root
        - group: root
      - /etc/gshadow-:
        - mode: {{ shadow_perms }}
        - user: root
        - group: root
        
## CIS 6.1.9 Ensure no world writable files exist
"df --local -P | awk '{if (NR!=1) print $6}' | xargs -I '{}' find '{}' -xdev -type f -perm -0002 | xargs -I '{}' chmod -v o-w '{}'": cmd.run

## CIS 6.1.10 Ensure no unowned files or directories exist
"df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -nouser | xargs -I '{}' chown root '{}'": cmd.run

## CIS 6.1.11 Ensure no ungrouped files or directories exist
"df --local -P | awk {'if (NR!=1) print $6'} | xargs -I '{}' find '{}' -xdev -nogroup | xargs -I '{}' chgrp root '{}'": cmd.run

## CIS 6.1.12 Ensure sticky bit is set on all world-writable directories
"df --local -P | awk '{if (NR!=1) print $6}' | xargs -I '{}' find '{}' -xdev -type d \\( -perm -0002 -a ! -perm -1000 \\) 2>/dev/null | xargs -I '{}' chmod a+t '{}'": cmd.run

## CIS 6.1.13 Audit SUID executables
# not easy this

## CIS 6.1.14 Audit SGID executables
# not easy this

## CIS 6.2 Local User and Group Settings
# not easy all this

