{% set minion = pillar.minion %}

send oscap file:
  file.managed:
    - source: salt://tmp/scan_report.html
    - name: /var/www/html/{{ minion }}_scan_report.html

