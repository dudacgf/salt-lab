libopenscap8:
  pkg.installed

install extras:
  pkg.installed:
    - sources:
      - ssg-base: http://br.archive.ubuntu.com/ubuntu/pool/universe/s/scap-security-guide/ssg-base_0.1.71-1_all.deb
      - ssg-debderived: http://br.archive.ubuntu.com/ubuntu/pool/universe/s/scap-security-guide/ssg-debderived_0.1.71-1_all.deb
    - skip_verify: True

run eval:
  cmd.run:
    - name: 'oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_cis_level2_server --results scan_results.xml --report scan_report.html --fetch-remote-resources  /usr/share/xml/scap/ssg/content/ssg-ubuntu2204-ds.xml > /dev/null 2>&1' 
    - require: 
      - pkg: install extras
      - pkg: libopenscap8

copy outputs:
  file.managed:
    - mode: 0644
    - names:
      - /tmp/scan_results.xml:
        - source: /root/scan_results.xml 
      - /tmp/scan_report.html:
        - source: /root/scan_report.html

