install packages:
  pkg.installed:
    - pkgs:
      - libopenscap25
      - ssg-base
      - ssg-debderived

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

