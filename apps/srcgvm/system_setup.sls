{% set version = {
        "GVM_LIBS_VERSION": "22.9.1", 
        "GVMD_VERSION": "23.6.2", 
        "PG_GVM_VERSION": "22.6.5", 
        "GSA_VERSION": "23.0.0", 
        "GSAD_VERSION": "22.9.1", 
        "OPENVAS_SMB_VERSION": "22.5.6", 
        "OPENVAS_SCANNER_VERSION": "23.3.1", 
        "OSPD_OPENVAS_VERSION": "22.7.1", 
        "OPENVAS_DAEMON": "23.3.1", 
        "RUST": "1.78.0"
       }
%}

copy redis conf:
  file.managed:
    - name: /etc/redis/redis-openvas.conf
    - source: /var/lib/builder/source/openvas-scanner-{{ version.OPENVAS_SCANNER_VERSION }}/config/redis-openvas.conf
    - user: redis
    - group: redis

add db address redis conf:
  file.append:
    - name: /etc/openvas/openvas.conf
    - text: "db_address = /run/redis-openvas/redis.sock"

redis-server@openvas.service:
  service.running:
    - enable: True
 
gvm:
  user.present:
    - groups: [ 'redis' ]
    - remove_groups: False

adjust permissions:
  cmd.run:
    - names:
      - chown gvm:gvm -R /var/lib/notus
      - chown gvm:gvm -R /var/lib/gvm
      - chown gvm:gvm -R /var/lib/openvas
      - chown gvm:gvm -R /var/log/gvm
      - chmod -R g+srw /var/lib/gvm
      - chmod -R g+srw /var/lib/openvas
      - chmod -R g+srw /var/log/gvm
      - chown gvm:gvm /usr/local/sbin/gvmd
      - chmod 6750 /usr/local/sbin/gvmd
      - chown -R gvm:gvm /usr/local/share/gvm/gsad

/var/lib/gvm/community_feed_signing:
  file.managed:
    - mode: 0755
    - contents: |
        curl -f -L https://www.greenbone.net/GBCommunitySigningKey.asc -o /tmp/GBCommunitySigningKey.asc
        export GNUPGHOME=/tmp/openvas-gnupg
        mkdir -p $GNUPGHOME
        gpg --import /tmp/GBCommunitySigningKey.asc
        echo "8AE4BE429B60A59B311C2E739823FAA60ED1E580:6:" | gpg --import-ownertrust
        export OPENVAS_GNUPG_HOME=/etc/openvas/gnupg
        sudo mkdir -p $OPENVAS_GNUPG_HOME
        sudo cp -r /tmp/openvas-gnupg/* $OPENVAS_GNUPG_HOME/
        sudo chown -R gvm:gvm $OPENVAS_GNUPG_HOME

community feed signing:
  cmd.run:
    - name: '/var/lib/gvm/community_feed_signing'
    - require:
      - file: /var/lib/gvm/community_feed_signing

/etc/sudoers.d/99_gvm_openvas:
  file.managed:
    - contents: ['# allow users of the gvm group run openvas', '%gvm ALL = NOPASSWD: /usr/local/sbin/openvas']

postgresql@15-main.service:
  service.running:
    - enable: True

/var/lib/gvm/postgresql-createdb:
  file.managed:
    - user: gvm
    - group: gvm
    - mode: 0755
    - contents: |
        # Setting up PostgreSQL user and database for the Greenbone Community Edition
        sudo -u postgres bash <<__EOF
        cd
        createuser -DRS gvm
        createdb -O gvm gvmd
        psql gvmd -c "create role dba with superuser noinherit; grant dba to gvm;"
        exit
        __EOF


postgresql-createdb:
  cmd.run:
    - name: /var/lib/gvm/postgresql-createdb
    - require:
      - file: /var/lib/gvm/postgresql-createdb

create user admin:
  cmd.run:
    - name: "/usr/local/sbin/gvmd --create-user=admin --password='{{ pillar.gsad_admin_pw }}'"
    - run_as: gvm

set feed import owner:
  cmd.run:
    - name: "/usr/local/sbin/gvmd --modify-setting 78eceaec-3385-11ea-b237-28d24461215b --value `/usr/local/sbin/gvmd --get-users --verbose | grep admin | awk '{print $2}'`"
    - run_as: gvm

/etc/systemd/system/ospd-openvas.service:
  file.managed:
    - contents: |
        [Unit]
        Description=OSPd Wrapper for the OpenVAS Scanner (ospd-openvas)
        Documentation=man:ospd-openvas(8) man:openvas(8)
        After=network.target networking.service redis-server@openvas.service mosquitto.service
        Wants=redis-server@openvas.service mosquitto.service notus-scanner.service
        ConditionKernelCommandLine=!recovery

        [Service]
        Type=exec
        User=gvm
        Group=gvm
        RuntimeDirectory=ospd
        RuntimeDirectoryMode=2775
        PIDFile=/run/ospd/ospd-openvas.pid
        ExecStart=/usr/local/bin/ospd-openvas --foreground --unix-socket /run/ospd/ospd-openvas.sock --pid-file /run/ospd/ospd-openvas.pid --log-file /var/log/gvm/ospd-openvas.log --lock-file-dir /var/lib/openvas --socket-mode 0o770 --mqtt-broker-address localhost --mqtt-broker-port 1883 --notus-feed-dir /var/lib/notus/advisories --log-level DEBUG
        SuccessExitStatus=SIGKILL
        Restart=always
        RestartSec=60

        [Install]
        WantedBy=multi-user.target

/etc/systemd/system/gvmd.service:
  file.managed:
    - contents: |
        [Unit]
        Description=Greenbone Vulnerability Manager daemon (gvmd)
        After=network.target networking.service postgresql.service ospd-openvas.service
        Wants=postgresql.service ospd-openvas.service
        Documentation=man:gvmd(8)
        ConditionKernelCommandLine=!recovery

        [Service]
        Type=exec
        User=gvm
        Group=gvm
        PIDFile=/run/gvmd/gvmd.pid
        RuntimeDirectory=gvmd
        RuntimeDirectoryMode=2775
        ExecStart=/usr/local/sbin/gvmd --foreground --osp-vt-update=/run/ospd/ospd-openvas.sock --listen-group=gvm
        Restart=always
        TimeoutStopSec=10

        [Install]
        WantedBy=multi-user.target

/etc/systemd/system/gsad.service:
  file.managed:
    - contents: |
        [Unit]
        Description=Greenbone Security Assistant daemon (gsad)
        Documentation=man:gsad(8) https://www.greenbone.net
        After=network.target gvmd.service
        Wants=gvmd.service

        [Service]
        Type=exec
        User=gvm
        Group=gvm
        RuntimeDirectory=gsad
        RuntimeDirectoryMode=2775
        PIDFile=/run/gsad/gsad.pid
        ExecStart=/usr/local/sbin/gsad --foreground --listen=127.0.0.1 --port=9392 --http-only
        Restart=always
        TimeoutStopSec=10

        [Install]
        WantedBy=multi-user.target
        Alias=greenbone-security-assistant.service

/etc/systemd/system/notus-scanner.service:
  file.managed:
    - contents: |
        [Unit]
        Description=Notus Scanner
        Documentation=https://github.com/greenbone/notus-scanner
        After=mosquitto.service
        Wants=mosquitto.service
        ConditionKernelCommandLine=!recovery

        [Service]
        Type=exec
        User=gvm
        RuntimeDirectory=notus-scanner
        RuntimeDirectoryMode=2775
        PIDFile=/run/notus-scanner/notus-scanner.pid
        ExecStart=/usr/local/bin/notus-scanner --foreground --products-directory /var/lib/notus/products --log-file /var/log/gvm/notus-scanner.log
        SuccessExitStatus=SIGKILL
        Restart=always
        RestartSec=60

        [Install]
        WantedBy=multi-user.target

/etc/systemd/system/openvasd.service:
  file.managed:
    - contents: |
        [Unit]
        Description=OpenVASD
        Documentation=https://github.com/greenbone/openvas-scanner/tree/main/rust/openvasd
        ConditionKernelCommandLine=!recovery
        [Service]
        Type=exec
        User=gvm
        RuntimeDirectory=openvasd
        RuntimeDirectoryMode=2775
        ExecStart=/usr/local/bin/openvasd --mode service_notus --products /var/lib/notus/products --advisories /var/lib/notus/advisories --listening 127.0.0.1:3000 --ospd-socket /var/run/ospd-openvas.sock
        SuccessExitStatus=SIGKILL
        Restart=always
        RestartSec=60
        [Install]
        WantedBy=multi-user.target

apache proxy:
  file.managed:
    - name: /etc/apache2/conf-available/gsad.conf
    - contents: |
        # gsad
        #
        <Location />
           Order allow,deny
           Allow from all
           #
           ProxyPass http://localhost:9392/
           ProxyPassReverse http://localhost:9392/
        </Location>

gsad:
  apache_conf.enabled

proxy:
  apache_module.enabled

proxy_http:
  apache_module.enabled

apache2.service: 
  service.running:
    - enable: True
    - reload: True
    - watch:
      - file: /etc/apache2/conf-available/gsad.conf
    

