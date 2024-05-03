{% if grains['osmajorrelease'] > 12 %}
install packages:
  pkg.installed:
    - pkgs:
      - libopenscap25
      - ssg-base
      - ssg-debian
{% else %}
install packages:
  pkg.installed:
    - pkgs:
      - libopenscap8
install extras:
  pkg.installed:
    - sources:
      - ssg-base: http://debian.c3sl.ufpr.br/debian/pool/main/s/scap-security-guide/ssg-base_0.1.71-1_all.deb
      - ssg-debian: http://debian.c3sl.ufpr.br/debian/pool/main/s/scap-security-guide/ssg-debian_0.1.71-1_all.deb
{% endif %}
run eval:
  cmd.run:
    - name: 'oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_cis_level2_server --results /tmp/scan_results.xml --report /tmp/scan_report.html --fetch-remote-resources  /usr/share/xml/scap/ssg/content/ssg-ubuntu2204-ds.xml > /dev/null 2>&1' 
    - require: 
      - pkg: install packages

