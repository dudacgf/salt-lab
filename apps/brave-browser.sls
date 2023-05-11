{% if grains['os_family'] == 'Debian' %}
/usr/share/keyrings/brave-browser-archive-keyring.gpg:
  file.managed:
    - source: https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
    - skip_verify: True
    - makedirs: True

repo brave:
  pkgrepo.managed:
    - name: "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main"
    - baseurl: https://brave-browser-apt-release.s3.brave.com/ 
    - humanname: Debian - Brave Browser
    - file: /etc/apt/sources.list.d/brave.list
    - key_url: https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

{% elif grains['os_family'] == 'RedHat' %}
repo brave:
  pkgrepo.managed:
    - name: Brave-Browser
    - baseurl: https://brave-browser-rpm-release.s3.brave.com/x86_64/
    - file: /etc/yum.repos.d/brave.repo
    - gpgkey: https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
    - gpgcheck: 1

{% endif %}

brave-browser:
  pkg.installed:
    - refresh: True
    - require:
      - repo brave
