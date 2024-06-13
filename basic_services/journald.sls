## 4.2.1.1.1 Ensure journald is configured to send logs to a remote log host
## I'll implement this using pillars that will depict if this server will upload to and/or receive from
## logs of others servers.
## see pillar_sample/organization.sls
##
systemd-journal-remote:
  pkg.installed

## 4.2.1.1.2 Ensure systemd-journal-remote is configured
/etc/ssl/private/journal-privkey.pem:
  file.managed:
    - source: {{ pillar.journal.cert }}
    - makedirs: True

/etc/ssl/certs/journal-cert.pem:
  file.managed:
    - source: {{ pillar.journal.privkey }}

/etc/ssl/ca/CA_Icatu.pem:
  file.managed:
    - source: {{ pillar.journal.ca }}
    - makedirs: True

## is this an upload server?
{% if pillar.journal.upload | default(False) %}
/etc/systemd/journal-upload.conf:
  file.managed:
    - contents: |
          [Upload]
          URL={{ pillar.journal.url }}
          ServerKeyFile=/etc/ssl/private/journal-privkey.pem
          ServerCertificateFile=/etc/ssl/certs/journal-cert.pem
          TrustedCertificateFile=/etc/ssl/ca/CA_Icatu.pem

## 4.2.1.1.3 Ensure systemd-journal-upload is enabled 
systemd-journal-upload.service:
  service.running:
    - enable: True
    - watch:
      - file: /etc/systemd/journal-upload.conf

{% endif %}
{% if pillar.journal.remote | default(False) %}
/etc/systemd/journal-remote.conf:
  file.managed:
    - contents: |
          [Remote]
          # Seal=false
          # SplitMode=host
          ServerKeyFile=/etc/ssl/private/journal-privkey.pem
          ServerCertificateFile=/etc/ssl/certs/journal-cert.pem
          TrustedCertificateFile=/etc/ssl/ca/CA_Icatu.pem

## 
systemd-journal-remote.service:
  service.running:
    - enable: True
    - watch:
      - file: /etc/systemd/journal-remote.conf
{% else %}
## 4.2.1.1.4 Ensure journald is not configured to receive logs from a remote client
'systemctl stop systemd-journal-remote.socket': cmd.run
'systemctl mask systemd-journal-remote.socket': cmd.run
{% endif %}

## 4.2.1.3 Ensure journald is configured to compress large log files
## 4.2.1.4 Ensure journald is configured to write logfiles to persistent disk 
## 4.2.1.5 Ensure journald is not configured to send logs to rsyslog
## 4.2.1.6 Ensure journald log rotation is configured per site policy
/etc/systemd/journald.conf:
  file.managed:
    - contents: |
         [Journal]
         Compress=yes
         Storage=persistent
         ForwardToSyslog=no
         SystemMaxUse=15
         SystemKeepFree=15
         RuntimeMaxUse=15
         RuntimeKeepFree=15
         MaxFileSec=1year

## 4.2.1.2 Ensure journald service is enabled
systemd-journald:
  service.running:
    - enable: True
    - restart: True
    - watch: 
      - file: /etc/systemd/journald.conf

## 4.2.1.7 Ensure journald default file permissions configured
/usr/lib/tmpfiles.d/systemd.conf:
  file.managed:
    - mode: 0640

