systemctl restart {{ pillar['pkg_data']['apache']['service'] }}:
  cmd.run
