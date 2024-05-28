gvm:
  user.present:
    - shell: /usr/sbin/nologin
    - fullname: Greenbone Vulnerability Manager
    - home: /var/lib/gvm

duda:
  user.present:
    - groups: [ 'gvm' ]
    - remove_groups: False

create_dirs:
  file.directory:
    - names:
      - /var/lib/gvm/source
      - /var/lib/gvm/build
      - /var/lib/gvm/install
      - /var/lib/gvm/.gnupg:
        - mode: 0700
    - user: gvm
    - group: gvm

Greenbone signing key:
  gpg.present:
    - trust: ultimately
    - name: 9823FAA60ED1E580
    - user: gvm
    - keyserver: https://keys.gnupg.net

install_prereqs:
  pkg.installed:
    - refresh: True
    - pkgs:
      - bison 
      - dpkg 
      - fakeroot 
      - gcc-mingw-w64 
      - gnupg 
      - gnutls-bin 
      - gpgsm 
      - heimdal-dev 
      - libbsd-dev 
      - libcurl4-gnutls-dev 
      - libgcrypt20-dev 
      - libglib2.0-dev 
      - libgnutls28-dev 
      - libgpgme-dev 
      - libhiredis-dev 
      - libical-dev 
      - libjson-glib-dev 
      - libksba-dev 
      - libldap2-dev 
      - libmicrohttpd-dev 
      - libnet1-dev 
      - libpaho-mqtt-dev 
      - libpcap-dev 
      - libpopt-dev 
      - libpq-dev 
      - libradcli-dev
      - libsnmp-dev
      - libssh-gcrypt-dev 
      - libssl-dev
      - libunistring-dev 
      - libxml2-dev 
      - nmap 
      - nsis 
      - openssh-client 
      - perl-base
      - pkg-config 
      - postgresql-server-dev-15 
      - python3 
      - python3-cffi 
      - python3-defusedxml 
      - python3-gnupg 
      - python3-impacket 
      - python3-lxml 
      - python3-packaging 
      - python3-paho-mqtt
      - python3-paramiko
      - python3-pip
      - python3-psutil 
      - python3-redis 
      - python3-setuptools 
      - python3-venv 
      - python3-wrapt 
      - rpm 
      - rsync 
      - rust-all 
      - smbclient 
      - snmp 
      - socat 
      - sshpass 
      - texlive-fonts-recommended 
      - texlive-latex-extra 
      - uuid-dev 
      - wget 
      - xml-twig-tools
      - xmlstarlet 
      - xsltproc 
      - zip 


