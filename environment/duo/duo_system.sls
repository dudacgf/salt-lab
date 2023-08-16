#
## duo_system.sls - configures duo security for system-wide authentication and sudo
#

{% if grains['os_family'] == 'RedHat' and grains['osmajorrelease'] == 9 %}
system-wide auth:
  file.replace:
    - name: /etc/pam.d/system-auth
    - pattern: '^auth.*sufficient.*pam_unix.so.*$'
    - repl: |
        auth        requisite      pam_unix.so try_first_pass nullok
        auth        sufficient     pam_duo.so

{%- if pillar['duo']['sudo'] | default(False) %}
/etc/pam.d/sudo:
  file.replace:
    - pattern: '^auth.*include.*system-auth'
    - repl: |
        auth required pam_env.so
        auth requisite pam_unix.so
        auth sufficient pam_duo.so
        auth required pam_deny.so
{%- endif %}

{% elif grains['os_family'] == 'Debian' %}
system-wide auth:
  file.replace:
    - name: /etc/pam.d/common-auth
    - pattern: '^auth.*\[success=1.*nullok_secure$'
    - repl: |
        auth  requisite pam_unix.so nullok_secure
        auth  [success=1 default=ignore] /usr/lib64/security/pam_duo.so

{%- if pillar['duo']['sudo'] | default(False) %}
/etc/pam.d/sudo:
{%- if grains['os'] == 'Debian' %}
{%- set pattern = '@include common-auth' %}
{%- elif grains['os'] == 'Ubuntu' %}
{%- set pattern = 'session    required   pam_limits.so' %}
{%- endif %}
  file.replace:
    - pattern: '^{{ pattern }}$'
    - repl: |
        #{{ pattern }}  ## replaced
        auth       required   pam_env.so
        auth       requisite  pam_unix.so
        auth       sufficient /usr/lib64/security/pam_duo.so
        auth       required   pam_deny.so
{%- endif %}

{% endif %} # if grains['os']
