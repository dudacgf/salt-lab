{% set version = {
        "GVM_LIBS_VERSION": "22.12.2", 
        "GVMD_VERSION": "23.10.0", 
        "PG_GVM_VERSION": "22.6.5", 
        "GSA_VERSION": "23.3.0", 
        "GSAD_VERSION": "22.9.1", 
        "OPENVAS_SMB_VERSION": "22.5.6", 
        "OPENVAS_SCANNER_VERSION": "23.9.0", 
        "NOTUS_SCANNER_VERSION": "22.6.3",
        "OSPD_OPENVAS_VERSION": "22.7.1", 
        "OPENVAS_DAEMON": "23.3.1", 
        "RUST": "1.78.0"
       }
%}

install rust:
  cmd.run:
    - name: 'bash /var/lib/builder/source/rust-{{ version.RUST }}-x86_64-unknown-linux-gnu/install.sh'
  
make gvm_libs:
  cmd.run:
    - name: "cmake /var/lib/builder/source/gvm-libs-{{ version.GVM_LIBS_VERSION }} -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_BUILD_TYPE=Release -DSYSCONFDIR=/etc -DLOCALSTATEDIR=/var; make -j$(nproc)"
    - cwd: /var/lib/builder/build/gvm-libs
    - run_as: builder

make install gvm_libs:
  cmd.run:
    - name: "make DESTDIR=/var/lib/builder/install/gvm-libs install"
    - cwd: /var/lib/builder/build/gvm-libs
    - run_as: builder

install gvm_libs:
  cmd.run:
    - name: "cp -rv /var/lib/builder/install/gvm-libs/* /"
    - require:
      - cmd: make install gvm_libs

make gvmd:
  cmd.run:
    - name: "PKG_CONFIG_PATH=/usr/local/lib/pkgconfig cmake /var/lib/builder/source/gvmd-{{ version.GVMD_VERSION }} -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_BUILD_TYPE=Release -DLOCALSTATEDIR=/var -DSYSCONFDIR=/etc -DGVM_DATA_DIR=/var -DGVMD_RUN_DIR=/run/gvmd -DOPENVAS_DEFAULT_SOCKET=/run/ospd/ospd-openvas.sock -DGVM_FEED_LOCK_PATH=/var/lib/gvm/feed-update.lock -DSYSTEMD_SERVICE_DIR=/usr/lib/systemd/system -DLOGROTATE_DIR=/etc/logrotate.d; make -j$(nproc)"
    - cwd: /var/lib/builder/build/gvmd
    - run_as: builder

make install gvmd:
  cmd.run:
    - name: "make DESTDIR=/var/lib/builder/install/gvmd install"
    - cwd: /var/lib/builder/build/gvmd
    - run_as: builder

install gvmd:
  cmd.run:
    - name: "cp -rv /var/lib/builder/install/gvmd/* /"
    - require:
      - cmd: make install gvmd

make pg-gvm:
  cmd.run:
    - name: "PKG_CONFIG_PATH=/usr/local/lib/pkgconfig cmake /var/lib/builder/source/pg-gvm-{{ version.PG_GVM_VERSION }} -DCMAKE_BUILD_TYPE=Release; make -j$(nproc)"
    - cwd: /var/lib/builder/build/pg-gvm
    - run_as: builder

make install pg-gvm:
  cmd.run:
    - name: "make DESTDIR=/var/lib/builder/install/pg-gvm install"
    - cwd: /var/lib/builder/build/pg-gvm
    - run_as: builder

install pg-gvm:
  cmd.run:
    - name: "cp -rv /var/lib/builder/install/pg-gvm/* /"
    - require:
      - cmd: make install pg-gvm

mkdir -p /usr/local/share/gvm/gsad/web: cmd.run

install gsa:
  cmd.run:
    - name: "cp -rv /var/lib/builder/source/gsa-{{ version.GSA_VERSION }}/* /usr/local/share/gvm/gsad/web/"

make gsad:
  cmd.run:
    - name: "PKG_CONFIG_PATH=/usr/local/lib/pkgconfig cmake /var/lib/builder/source//gsad-{{ version.GSAD_VERSION }} -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_BUILD_TYPE=Release -DSYSCONFDIR=/etc -DLOCALSTATEDIR=/var -DSYSTEMD_SERVICE_DIR=/usr/lib/systemd/system -DGVMD_RUN_DIR=/run/gvmd -DGSAD_RUN_DIR=/run/gsad -DLOGROTATE_DIR=/etc/logrotate.d; make -j$(nproc)"
    - cwd: /var/lib/builder/build/gsad
    - run_as: builder

make install gsad:
  cmd.run:
    - name: "make DESTDIR=/var/lib/builder/install/gsad install"
    - cwd: /var/lib/builder/build/gsad
    - run_as: builder

install gsad:
  cmd.run:
    - name: "sudo cp -rv /var/lib/builder/install/gsad/* /"
    - require:
      - cmd: make install gsad

make openvas-smb:
  cmd.run:
    - name: "PKG_CONFIG_PATH=/usr/local/lib/pkgconfig cmake /var/lib/builder/source/openvas-smb-{{ version.OPENVAS_SMB_VERSION }} -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_BUILD_TYPE=Release; make -j$(nproc)"
    - cwd: /var/lib/builder/build/openvas-smb
    - run_as: builder

make install openvas-smb:
  cmd.run:
    - name: "make DESTDIR=/var/lib/builder/install/openvas-smb install"
    - cwd: /var/lib/builder/build/openvas-smb
    - run_as: builder

install openvas-smb:
  cmd.run:
    - name: "sudo cp -rv /var/lib/builder/install/openvas-smb/* /"
    - require:
      - cmd: make install openvas-smb

make openvas-scanner:
  cmd.run:
    - name: "PKG_CONFIG_PATH=/usr/local/lib/pkgconfig cmake /var/lib/builder/source/openvas-scanner-{{ version.OPENVAS_SCANNER_VERSION }} -DCMAKE_INSTALL_PREFIX=/usr/local -DCMAKE_BUILD_TYPE=Release -DINSTALL_OLD_SYNC_SCRIPT=OFF -DSYSCONFDIR=/etc -DLOCALSTATEDIR=/var -DOPENVAS_FEED_LOCK_PATH=/var/lib/openvas/feed-update.lock -DOPENVAS_RUN_DIR=/run/ospd; make -j$(nproc)"
    - cwd: /var/lib/builder/build/openvas-scanner
    - run_as: builder

make install openvas-scanner:
  cmd.run:
    - name: "make DESTDIR=/var/lib/builder/install/openvas-scanner install"
    - cwd: /var/lib/builder/build/openvas-scanner
    - run_as: builder

install openvas-scanner:
  cmd.run:
    - name: "sudo cp -rv /var/lib/builder/install/openvas-scanner/* /"
    - require:
      - cmd: make install openvas-scanner

make ospd-openvas:
  cmd.run:
    - name: "python3 -m pip install --root=/var/lib/builder/install/ospd-openvas --no-warn-script-location ."
    - cwd: /var/lib/builder/source/ospd-openvas-{{ version.OSPD_OPENVAS_VERSION }}
    - run_as: builder

install ospd-openvas:
  cmd.run:
    - name: "cp -rv /var/lib/builder/install/ospd-openvas/* /"
    - require:
      - cmd: make ospd-openvas

make openvasd:
  cmd.run:
    - name: "cargo build --release"
    - cwd: /var/lib/builder/source/openvas-scanner-{{ version.OPENVAS_DAEMON }}/rust/openvasd
    - run_as: builder

make scannerctl:
  cmd.run:
    - name: "cargo build --release"
    - cwd: /var/lib/builder/source/openvas-scanner-{{ version.OPENVAS_DAEMON }}/rust/scannerctl
    - run_as: builder

install openvasd scannerctl:
  file.managed:
    - mode: 0755
    - names:
      - /usr/local/bin/openvasd:
        - source: /var/lib/builder/source/openvas-scanner-{{ version.OPENVAS_DAEMON }}/rust/target/release/openvasd
      - /usr/local/bin/scannerctl:
        - source: /var/lib/builder/source/openvas-scanner-{{ version.OPENVAS_DAEMON }}/rust/target/release/scannerctl
    - require:
      - cmd: make openvasd 
      - cmd: make scannerctl

make notus-scanner:
  cmd.run: 
    - name: "python3 -m pip install --root=/var/lib/builder/install/notus-scanner --no-warn-script-location ."
    - cwd: /var/lib/builder/source/notus-scanner-{{ version.NOTUS_SCANNER_VERSION }}
    - run_as: builder

install notus-scanner:
  cmd.run:
    - name: "cp -rv /var/lib/builder/install/notus-scanner/* /"
    - require:
      - cmd: make notus-scanner

make install greenbone feed sync:
  cmd.run:
    - name: "python3 -m pip install --root=/var/lib/builder/install/greenbone-feed-sync --no-warn-script-location greenbone-feed-sync"
    - cwd: /var/lib/builder/source/gvmd-{{ version.GVMD_VERSION }}/tools
    - run_as user: builder

install greenbone feed sync:
  cmd.run:
    - name: "cp -rv /var/lib/builder/install/greenbone-feed-sync/* /"

make gvm-tools:
  cmd.run:
    - name: "python3 -m pip install --root=/var/lib/builder/install/gvm-tools --no-warn-script-location gvm-tools"

install gvm-tools:
  cmd.run:
    - name: "sudo cp -rv /var/lib/builder/install/gvm-tools/* /"

/etc/ld.so.conf.d/gvm.conf:
  file.managed:
    - contents: /usr/local/lib

/usr/sbin/ldconfig:
  cmd.run

