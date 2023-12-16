###
# we will upgrade salt to 3006.4 but for this I need python >= 3.10
# 
install complete python3.11:
  pkg.installed:
    - pkgs:
        - libpython3_11-1_0
        - python311
        - python311-apipkg
        - python311-appdirs
        - python311-asn1crypto
        - python311-attrs
        - python311-Automat
        - python311-Babel
        - python311-base
        - python311-bcrypt
        - python311-certifi
        - python311-cffi
        - python311-chardet
        - python311-configobj
        - python311-constantly
        - python311-contextvars
        - python311-cryptography
        - python311-curses
        - python311-dbm
        - python311-decorator
        - python311-devel
        - python311-dnspython
        - python311-ecdsa
        - python311-gevent
        - python311-gobject
        - python311-gobject-cairo
        - python311-greenlet
        - python311-h2
        - python311-hpack
        - python311-hyperframe
        - python311-hyperlink
        - python311-idna
        - python311-immutables
        - python311-incremental
        - python311-iniconfig
        - python311-Jinja2
        - python311-MarkupSafe
        - python311-numpy
        - python311-packaging
        - python311-paramiko
        - python311-pexpect
        - python311-pip
        - python311-ply
        - python311-psutil
        - python311-ptyprocess
        - python311-py
        - python311-pyasn1
        - python311-pyasn1-modules
        - python311-pycairo
        - python311-pycares
        - python311-pycparser
        - python311-pycurl
        - python311-PyHamcrest
        - python311-pyinotify
        - python311-PyNaCl
        - python311-pyOpenSSL
        - python311-pyparsing
        - python311-pyserial
        - python311-PySocks
        - python311-pytz
        - python311-pyudev
        - python311-PyYAML
        - python311-requests
        - python311-service_identity
        - python311-setuptools
        - python311-simplejson
        - python311-six
        - python311-tornado
        - python311-Twisted
        - python311-typing_extensions
        - python311-urllib3
        - python311-zope.interface

# use pip3.11 to install latest salt
{% if pillar.proxy %}
pip3.11 config set global.proxy {{ pillar.proxy }}:
  cmd.run
{% endif %}
pip3.11 -q install salt:
  cmd.run

# change hashbang on salt-commands to point to python3.11
/usr/bin/salt-minion:
  file.replace:
    - pattern: '^#\!/usr/bin/python3$'
    - repl: '#!/usr/bin/python3.11'
/usr/bin/salt-call:
  file.replace:
    - pattern: '^#\!/usr/bin/python3$'
    - repl: '#!/usr/bin/python3.11'
/usr/bin/salt-support:
  file.replace:
    - pattern: '^#\!/usr/bin/python3$'
    - repl: '#!/usr/bin/python3.11'

# restart salt-minion
salt-minion:
  service.running:
    - restart: True
    - require:
      - pkg: install complete python3.11
      - cmd: pip3.11 -q install salt
      - file: /usr/bin/salt*
