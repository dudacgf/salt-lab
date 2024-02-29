# desabilita root login
usermod -p '!' root:
  cmd.run:
    - unless: eval [ `passwd -S root | grep -E '^root L' -c` -gt 0 ]

chage -d $(date +%C%y-%m-%d -d "-30 days") root:
  cmd.run
