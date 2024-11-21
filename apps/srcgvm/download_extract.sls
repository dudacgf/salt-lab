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

gvm_libs:
  archive.extracted:
    - name: /var/lib/builder/source/
    - source: https://github.com/greenbone/gvm-libs/archive/refs/tags/v{{ version.GVM_LIBS_VERSION }}.tar.gz
    - skip_verify: True
    - user: builder
    - group: builder


GVMD:
  archive.extracted:
    - name: /var/lib/builder/source
    - source: https://github.com/greenbone/gvmd/archive/refs/tags/v{{ version.GVMD_VERSION }}.tar.gz
    - skip_verify: True
    - user: builder
    - group: builder

PG-GVM:
  archive.extracted:
    - name: /var/lib/builder/source
    - source: https://github.com/greenbone/pg-gvm/archive/refs/tags/v{{ version.PG_GVM_VERSION }}.tar.gz
    - skip_verify: True
    - user: builder
    - group: builder

GSA:
  archive.extracted:
    - name: /var/lib/builder/source/gsa-{{ version.GSA_VERSION }}
    - source: https://github.com/greenbone/gsa/releases/download/v{{ version.GSA_VERSION }}/gsa-dist-{{ version.GSA_VERSION }}.tar.gz
    - skip_verify: True
    - user: builder
    - group: builder

GSAD:
  archive.extracted:
    - name: /var/lib/builder/source/
    - source: https://github.com/greenbone/gsad/archive/refs/tags/v{{ version.GSAD_VERSION }}.tar.gz
    - skip_verify: True
    - user: builder
    - group: builder

OPENVAS-SMB:
  archive.extracted:
    - name: /var/lib/builder/source
    - source: https://github.com/greenbone/openvas-smb/archive/refs/tags/v{{ version.OPENVAS_SMB_VERSION }}.tar.gz
    - skip_verify: True
    - user: builder
    - group: builder

OPENVAS-SCANNER:
  archive.extracted:
    - name: /var/lib/builder/source
    - source: https://github.com/greenbone/openvas-scanner/archive/refs/tags/v{{ version.OPENVAS_SCANNER_VERSION }}.tar.gz
    - skip_verify: True
    - user: builder
    - group: builder

OSPD-OPENVAS:
  archive.extracted:
    - name: /var/lib/builder/source
    - source: https://github.com/greenbone/ospd-openvas/archive/refs/tags/v{{ version.OSPD_OPENVAS_VERSION }}.tar.gz
    - skip_verify: True
    - user: builder
    - group: builder

NOTUS-SCANNER:
  archive.extracted:
    - name: /var/lib/builder/source
    - source: https://github.com/greenbone/notus-scanner/archive/refs/tags/v{{ version.NOTUS_SCANNER_VERSION }}.tar.gz
    - skip_verify: True
    - user: builder
    - group: builder

OPENVAS-DAEMON:
  archive.extracted:
    - name: /var/lib/builder/source
    - source: https://github.com/greenbone/openvas-scanner/archive/refs/tags/v{{ version.OPENVAS_DAEMON }}.tar.gz
    - skip_verify: True
    - user: builder
    - group: builder

RUST:
  archive.extracted:
    - name: /var/lib/builder/source
    - source: https://static.rust-lang.org/dist/rust-{{ version.RUST }}-x86_64-unknown-linux-gnu.tar.xz
    - skip_verify: True
    - user: builder
    - group: builder

