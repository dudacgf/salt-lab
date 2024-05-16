{%- import_yaml "maps/pkg_data/" + grains.os_family | lower + ".yaml" as pkg_data %}
#
## auditd.sls - instala e configura o serviço auditd para auditoria do servidor
# 
{{ pkg_data.audit.name }}:
  pkg.installed
  
{% if grains['os_family'] == 'Debian' %}
audispd-plugins:
  pkg.installed
{% endif %}

# CIS recomended auditd configuration settings
# CIS 4.1.2.1 Ensure audit log storage size is configured (max_log_file = 16)
# CIS 4.1.2.2 Ensure audit logs are not automatically deleted (max_log_file_actions = keep_logs)
# CIS 4.1.2.3 Ensure system is disabled when audit logs are full (admin_space_left_action = halt)
# CIS 4.1.4.1 Ensure audit log files are mode 0640 or less permissive
# CIS 4.1.4.2 Ensure only authorized users own audit log files
# CIS 4.1.4.4 Ensure the audit log directory is 0750 or more restrictive
##
/etc/audit/auditd.conf:
  file.managed:
    - source: salt://files/services/auditd/auditd.conf.jinja
    - user: root
    - group: root
    - mode: 640
    - template: jinja
    
# CIS recommended auditd rules
# CIS 4.1.3.1 Ensure changes to system administration scope (sudoers) is collected 
# CIS 4.1.3.2 Ensure actions as another user are always logged
# CIS 4.1.3.4 Ensure events that modify date and time information are collected
# CIS 4.1.3.5 Ensure events that modify the system's network environment are collected
# CIS 4.1.3.7 Ensure unsuccessful file access attempts are collected - b32 EACCES
# CIS 4.1.3.8 Ensure events that modify user/group information are collected 
# CIS 4.1.3.9 Ensure discretionary access control permission modification events are collected
# CIS 4.1.3.10 Ensure successful file system mounts are collected
# CIS 4.1.3.11 Ensure session initiation information is collected
# CIS 4.1.3.12 Ensure login and logout events are collected
# CIS 4.1.3.13 Ensure file deletion events by users are collected
# CIS 4.1.3.14 Ensure events that modify the system's Mandatory Access Controls are collected 
# CIS 4.1.3.15 Ensure successful and unsuccessful attempts to use the chcon command are recorded
# CIS 4.1.3.16 Ensure successful and unsuccessful attempts to use the setfacl command are recorded
# CIS 4.1.3.17 Ensure successful and unsuccessful attempts to use the chacl command are recorded 
# CIS 4.1.3.18 Ensure successful and unsuccessful attempts to use the usermod command are recorded 
# CIS 4.1.3.19 Ensure kernel module loading unloading and modification is collected
##
/etc/audit/rules.d/audit.rules:
  file.managed:
    - source: salt://files/services/auditd/audit.rules
    - user: root
    - group: root
    - mode: 600
    - backup: minion

# CIS 4.1.3.6 Ensure use of privileged commands are collected
add privileged commands:
  cmd.script:
    - source: salt://files/services/auditd/audit_privileged_commands.sh
    - cwd: /root

# CIS 4.1.3.20 Ensure the audit configuration is immutable
/etc/audit/rules.d/99-finalize.rules:
  file.managed:
    - contents: -e 2
    - mode: 0640

# CIS 4.1.1.3 Ensure auditing for processes that start prior to auditd is enabled
# CIS 4.1.1.4 Ensure audit_backlog_limit is sufficient 
##
{% if grains['os_family'] == 'Debian' %}
audit /etc/default/grub:
  file.line:
    - name: /etc/default/grub
    - after: '^GRUB_CMDLINE_LINUX=""$'
    - content: 'GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX audit=1 audit_backlog_limit=8192"'
    - mode: insert
    - unless: grep 'GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX audit=1"' /etc/default/grub

auditd-update-grub:
  cmd.run:
    - name: update-grub
    - onchanges:
      - file: /etc/default/grub
{% elif grains['os_family'] == 'RedHat' %}
grubby --update-kernel ALL --args 'audit=1': cmd.run
grubby --update-kernel ALL --args 'audit_backlog_limit=8192': cmd.run
{% endif %}
# CIS 4.1.4.4 Ensure the audit log directory is 0750 or more restrictive
/var/log/audit:
  file.directory:
    - dir_mode: 750
    - user: root
    - group: adm


# ajusta o serviço auditd
auditd.enabled:
  service.enabled:
    - name: auditd.service

# CIS recommends '-e 2' rule and so only boots reloads them. 
# I think this will result in error
restart auditd:
  cmd.run:
    - name: 'service auditd restart'
    - watch: 
      - file: /etc/audit/rules.d/audit.rules
      - file: /etc/audit/auditd.conf

