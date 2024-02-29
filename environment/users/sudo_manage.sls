#
# sudo configuration
#

# read map with os_family dependent info
{% import_yaml "maps/users/by_os_family.yaml" as osf %}
{% set osf = salt.grains.filter_by(osf) %}

#
## CIS 5.3.1 Ensure sudo is installed
sudo:
  pkg.installed

## CIS 5.3.5 Ensure re-authentication for privilege escalation is not disabled globally 
remove not authenticate:
  cmd.run: 
    - name:  "sed -i -- 's/^\\(.*\\)!authenticate/#\\1!authenticate/' /etc/sudoers /etc/sudoers.d/*"

## CIS 5.3.4 Ensure users must provide password for privilege escalation
remove nopasswd:
  file.replace:
    - name: /etc/sudoers
    - pattern: 'NOPASSWD:'
    - repl: 'ALL'

## I'll keep on using this insecure config bellow for wheel/sudo groups
00-pkg_app_{{ osf.sudo_group }}:
  file.managed:
    - name: /etc/sudoers.d/00-pkg_app
    - makedirs: true
    - contents: |
        #
        ## Allow people in group {{ osf.sudo_group }} to run all commands (with password)
        %{{ osf.sudo_group }}  ALL=(ALL)   ALL

        #
        ## Allow people in group {{ osf.sudo_group }} to manage apps (without password)
        {% for pkg_app in osf.pkg_apps -%}
        %{{ osf.sudo_group }}  ALL=(ALL)   NOPASSWD: {{ pkg_app }}
        {% endfor %}

{% if grains['os_family'] == 'RedHat' %}
/etc/sudoers.d/10-add-root:
  file.managed:
    - contents: |
        
        # 
        ## root on sudoers so that I don't get reported
        root    ALL=(ALL)   ALL
        
        #
        ## Read drop-in files from /etc/sudoers.d (the # here does not mean a comment)
        #includedir /etc/sudoers.d
{% elif grains['os_family'] == 'Suse' %}
/etc/sudoers:
  file.managed:
    - source: salt://files/users/sudoers_suse
{% endif %}

## CIS 5.3.3 Ensure sudo log file exists
/etc/sudoers.d/33_logfile:
  file.managed:
    - contents: Defaults logfile="/var/log/sudo.log"

## CIS 5.3.2 Ensure sudo commands use pty
/etc/sudoers.d/32_default_pty:
  file.managed:
    - contents: Defaults use_pty

## CIS 5.3.6 Ensure sudo authentication timeout is configured correctly
/etc/sudoers.d/36_timeout:
  file.managed:
    - contents: |
          Defaults env_reset, timestamp_timeout=15
          Defaults timestamp_timeout=15
          Defaults env_reset

## CIS 5.3.7 Ensure access to the su command is restricted
/etc/pam.d/su:
  file.append:
    - text: auth       required    pam_wheel.so use_uid
