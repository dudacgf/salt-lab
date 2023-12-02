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

### 0. Proxy - defines system wide proxy and configure proxy for apt/yum
{{ mname }} define proxy minion:
  salt.state:
    - sls: init.proxy
    - tgt: {{ mname }}

### 1. os_specific initialization (repos, yum/apt settings etc)
{{ mname }} os_specific:
   salt.state:
     - sls: init.os_specific
     - tgt: {{ mname }}

### 2. things needed for the following steps
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

### 3. NetworkManager
{{ mname }} network manager:
  salt.state:
    - sls: init.networkmanager
    - tgt: {{ mname }}

# waits (networkmanager may restart the minion)
{{ mname }} wait networkmanager:
  salt.wait_for_event:
    - name: salt/minion/*/start
    - id_list: [ '{{ mname }}' ]
    - timeout: 60
    - require:
      - salt: {{ mname }} network manager

### 4. install drivers, if needed
{{ mname }} install drivers:
  salt.state:
    - sls: drivers
    - tgt: {{ mname }}

# wait (install drivers reboots the minion)
{{ mname }} aguarda drivers:
  salt.wait_for_event:
    - name: salt/minion/*/start
    - id_list: [ "{{ mname }}" ]
    - timeout: 60
    - require:
      - salt: {{ mname }} install drivers

### 5. networkmanager connections 
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

### 6. executa o highstate desse minion
{% set hoi = salt['cmd.run']("salt " + mname + " pillar.item highstate_on_init") | load_yaml %}
{%- if hoi[mname]['highstate_on_init'] | default(False) %}

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
