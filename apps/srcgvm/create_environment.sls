group gvm:
  group.present:
    - name: gvm
    - gid: 987

user gvm:
  user.present:
    - name: gvm
    - shell: /usr/sbin/nologin
    - fullname: Greenbone Vulnerability Manager
    - uid: 987
    - gid: 987
    - allow_uid_change: True
    - allow_gid_change: True
    - password_lock: True
    - home: /var/lib/gvm

user builder:
  user.present:
    - name: builder
    - shell: /usr/sbin/nologin
    - home: /var/lib/builder
    - password_lock: True
    - optional_groups: ['gvm']

add duda to gvm group: # life will be easier for me
  user.present:
    - name: duda
    - groups: ['gvm']
    - remove_groups: False

create_dirs:
  file.directory:
    - names:
      - /var/lib/builder/source
      - /var/lib/builder/build
      - /var/lib/builder/install
      - /var/lib/builder/build/gvm-libs
      - /var/lib/builder/install/gvm-libs
      - /var/lib/builder/build/gvmd
      - /var/lib/builder/install/gvmd
      - /var/lib/builder/build/pg-gvm
      - /var/lib/builder/install/pg-gvm
      - /var/lib/builder/build/gsad
      - /var/lib/builder/install/gsad
      - /var/lib/builder/build/openvas-smb
      - /var/lib/builder/install/openvas-smb
      - /var/lib/builder/build/openvas-scanner
      - /var/lib/builder/install/openvas-scanner
      - /var/lib/builder/build/ospd-openvas
      - /var/lib/builder/install/ospd-openvas
      - /var/lib/builder/install/openvasd/usr/local/bin
      - /var/lib/builder/install/greenbone-feed-sync
      - /var/lib/builder/install/gvm-tools
      - /var/lib/builder/build/notus_scanner
      - /var/lib/builder/install/notus_scanner
      - /var/lib/notus
      - /run/gvm
      - /run/gvmd
      - /usr/share/gvm/gsad/web/:
        - user: root
        - group: root
    - makedirs: True
    - user: builder
    - group: builder

