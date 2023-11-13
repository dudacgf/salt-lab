{% if grains['os_family'] == 'Debian' %}
download gpg key:
  cmd.run: 
    - name:  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/microsoft.gpg

vscode repo:
  pkgrepo.managed:
    - name: "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/microsoft.gpg] https://packages.microsoft.com/repos/code stable main"
    - baseurl: deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main
    - humanname: Debian - Brave Browser
    - file: /etc/apt/sources.list.d/vscode.list

{% elif grains['os_family'] == 'RedHat' %}
vscode repo:
  pkgrepo.managed:
    - name: VSCode
    - baseurl: https://packages.microsoft.com/yumrepos/vscode
    - file: /etc/yum.repos.d/vscode.repo
    - gpgkey: https://packages.microsoft.com/keys/microsoft.asc
    - gpgcheck: 1
{% else %}
vscode repo:
  test.fail_without_changes:
    - name: '-- OS not supported'
{% endif %}

code:
  pkg.installed:
    - require:
      - vscode repo
