###
## Initializes networks and runs first highstate for a group of minions
#
#  You should call this as a orchestration, passing the name of the minions as a pillar:
#
#  sudo salt-run state.orch init pillar='{minions: [m1, m2, m3...]}'
#
#  (c) ecgf - mar/2023
#

{% for minion in pillar['minions'] | default([]) %}
{% set mname = pillar['minions'][minion]['name'] %}

#
### 0. Proxy - defines proxy for apt/yum and salt-minion
#

{{ mname }} define proxy minion:
  salt.state:
    - sls: init.proxy.proxy_minion
    - tgt: {{ mname }}

# waits (the previous state restarts salt-minion service)
{{ mname }} proxy restart:
  salt.wait_for_event:
    - name: salt/minion/*/start
    - id_list: [ '{{ mname }}' ]
    - timeout: {{ pillar['sleep_a_longer_while'] }}
    - require:
      - salt: {{ mname }} define proxy minion

{{ mname }} define proxy syspkg:
  salt.state:
    - sls: init.proxy.proxy_syspkg
    - tgt: {{ mname }}

#
### 1. os_specific initialization (repos, yum/apt settings etc)
{{ mname }} os_specific:
   salt.state:
     - sls: init.os_specific
     - tgt: {{ mname }}

#
### 2. things needed for the following steps
#
{{ mname }} essentials:
  salt.state:
    - sls: init.essentials
    - tgt: {{ mname }}

# waits (essentials restarts the minion)
{{ mname }} wait essentials:
  salt.wait_for_event:
    - name: salt/minion/*/start
    - id_list: [ '{{ mname }}' ]
    - timeout: 60
    - require:
      - salt: {{ mname }} essentials

#
### 3. NetworkManager
{{ mname }} network manager:
  salt.state:
    - sls: init.networkmanager
    - tgt: {{ mname }}

## waits (networkmanager may restart the minion)
{{ mname }} wait networkmanager:
  salt.wait_for_event:
    - name: salt/minion/*/start
    - id_list: [ '{{ mname }}' ]
    - timeout: 60
    - require:
      - salt: {{ mname }} network manager

##
# will need this in the following steps
{% set virtual_host = salt['cmd.run']("salt " + mname + " pillar.get virtual_host") | load_yaml %}

#
#
### 4. attach usb devices
#
#
{% set usb_devices = salt['cmd.run']("salt " + mname + " pillar.get usb_devices") | load_yaml %}
{% if usb_devices[mname]['attach'] | default(False) %}
{{ mname }} attach usb devices:
  salt.state:
    - sls: init.attach_usb
    - tgt: {{ virtual_host[mname] }}
    - pillar: {'usb_devices': {{ usb_devices[mname] }}, 'minion': {{ mname }} }
{% endif %}

#
#
### 5. install drivers, if needed
{{ mname }} install drivers:
  salt.state:
    - sls: drivers
    - tgt: {{ mname }}

#
## wait (install drivers reboots the minion)
{{ mname }} aguarda drivers:
  salt.wait_for_event:
    - name: salt/minion/*/start
    - id_list: [ "{{ mname }}" ]
    - timeout: 60
    - require:
      - salt: {{ mname }} install drivers

#
#
### 6. if host pillar defines interfaces, create them in the virtual_host and set it's ip address
#
#
## adds the network virtual interfaces to the minion (this is run in the virtual_host)
{%- set redefine = salt['cmd.run']("salt " + mname + " pillar.get redefine_interfaces") | load_yaml %}
{%- if redefine[mname] %}
    {%- set interfaces = salt['cmd.run']("salt " + mname + " pillar.get interfaces") | load_yaml %}
{{ mname }} add interfaces:
  salt.state:
    - sls: init.add_minion_interfaces
    - tgt: {{ virtual_host[mname] }}
    - pillar: {'minion_interfaces': {{ interfaces[mname] }}, 'minion': {{ mname }} }

#
## wait (add minion interfaces reboots the minion)
{{ mname }} aguarda interfaces:
  salt.wait_for_event:
    - name: salt/minion/*/start
    - id_list: [ "{{ mname }}" ]
    - timeout: 120
    - require:
      - salt: {{ mname }} add interfaces

#
## 6a. if redefine_proxy is set, redefine proxy
{% set proxy = salt.cmd.run('salt ' + mname + ' pillar.get redefine_proxy') | load_yaml %}

{{ mname }} redefine proxy minion:
  salt.state:
    - sls: init.proxy.proxy_minion
    - tgt: {{ mname }}
    - pillar: {'proxy': {{ proxy[mname] }} }

# waits (the previous state restarts salt-minion service)
{{ mname }} redefine proxy restart:
  salt.wait_for_event:
    - name: salt/minion/*/start
    - id_list: [ '{{ mname }}' ]
    - timeout: {{ pillar['sleep_a_longer_while'] }}
    - require:
      - salt: {{ mname }} redefine proxy minion

{{ mname }} redefine proxy syspkg:
  salt.state:
    - sls: init.proxy.proxy_syspkg
    - tgt: {{ mname }}
    - pillar: {'proxy': {{ proxy[mname] }} }

### 7. networkmanager connections 
{{ mname }} nmconnections:
  salt.state:
    - sls: init.nmconnections
    - tgt: {{ mname }} 
    - require:
      - salt: {{ mname }} network manager

# waits (the previous state may restart salt-minion service)
{{ mname }} wait nmconnections:
  salt.wait_for_event:
    - name: salt/minion/*/start
    - id_list: [ '{{ mname }}' ]
    - timeout: 120
    - require:
      - salt: {{ mname }} nmconnections

### 8. executa o highstate desse minion
{% set hoi = salt['cmd.run']("salt " + mname + " pillar.item highstate_on_init") | load_yaml %}
{%- if hoi[mname]['highstate_on_init'] | default(False) %}

## aguarda minion voltar ao ar

"-- {{ mname }} will execute high state":
  test.nop

{{ mname }} environment:
  salt.state:
    - sls: environment
    - tgt: {{ mname }}

{{ mname }} basic_services:
  salt.state:
    - sls: basic_services
    - tgt: {{ mname }}

{{ mname }} services:
  salt.state:
    - sls: services
    - tgt: {{ mname }}

{{ mname }} roles:
  salt.state:
    - sls: roles
    - tgt: {{ mname }}

{{ mname }} apps:
  salt.state:
    - sls: apps
    - tgt: {{ mname }}

{{ mname }} pkgs:
  salt.state:
    - sls: pkgs
    - tgt: {{ mname }}

{% else %}
"-- {{ mname }} will not execute high state":
  test.nop
{%- endif %}

{% endfor %} # minion in...
