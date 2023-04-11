{{ pillar['pkg_data']['apache']['confd_dir'] }}/zabbix.conf:
  file.append:
      - text: |
          
          RewriteCond %{HTTP_HOST} ^zabbix.theshiresco.com$
          RewriteRule "^/?$"      https://%{HTTP_HOST}/zabbix [R=302,L]

systemctl restart {{ pillar['pkg_data']['apache']['service'] }}:
  cmd.run:
    - watch:
      - file: {{ pillar['pkg_data']['apache']['confd_dir'] }}/zabbix.conf
