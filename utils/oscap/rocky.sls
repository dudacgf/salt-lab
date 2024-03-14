install oscap:
  pkg.installed:
    - pkgs: [ 'openscap-scanner', 'scap-security-guide' ]

run eval:
  cmd.run:
    - name: 'oscap xccdf eval --profile xccdf_org.ssgproject.content_profile_cis --results /tmp/scan_results.xml --report /tmp/scan_report.html --fetch-remote-resources /usr/share/xml/scap/ssg/content/ssg-rl9-ds.xml > /dev/null 2>&1' 
    - cwd: /root

