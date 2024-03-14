syslog-ng: pkg.removed

rsyslog: pkg.installed

Forward to syslog:
  file.replace:
    - name: /etc/systemd/journald.conf
    - pattern: '^ForwardToSyslog=no$'
    - repl: 'ForwardToSyslog=yes'

/etc/rsyslog.d/10_file_create_mode.conf:
  file.managed:
    - contents: |
          $FileCreateMode 0640
    - unless: 'grep FileCreate rsyslog.* -ri'

{% if pillar['audit2graylog'] | default(False) %}
/etc/rsyslog.d/12_audit2graylog.conf:
  file.managed:
    - contents: |
          *.* action(type="omfwd" target="192.168.2.100" port="514" protocol="tcp"
                     action.resumeRetryCount="100"
                     queue.type="LinkedList" queue.size="1000")
{% endif %}

systemd-journald.service:
  service.running:
    - restart: True
    - watch:
      - file: /etc/systemd/journald.conf
      - file: /etc/rsyslog.d/10_file_create_mode.conf
      {% if pillar['audit2graylog'] | default(False) %}
      - file: /etc/rsyslog.d/12_audit2graylog.conf
      {% endif %}

