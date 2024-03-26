###
## Initializes networks and runs first highstate for a group of minions
#
#  You should call this as a orchestration, passing the name of the minions as a pillar:
#
#  sudo salt-run state.orch init pillar='{minions: [m1, m2, m3...]}'
#
#  (c) ecgf - mar/2023
#

# get map for this minion
{% set map = pillar['map'] | default('production') %}
{% import_yaml 'maps/' + map + '.yaml' as minions %}
{% set minion = minions[pillar['minion']] %}
{% set mname = minion.name %}

### 0. Proxy - defines system wide proxy and configure proxy for apt/yum
{{ mname }} define proxy minion:
  salt.state:
    - sls: init.proxy
    - tgt: {{ mname }}
    - pillar: {'proxy': {{ minion.proxy | default(False) }}}

### 1. os_specific initialization (repos, yum/apt settings etc)
{{ mname }} os_specific:
  salt.state:
    - sls: init.os_specific
    - tgt: {{ mname }}
    - pillar: {"proxy": {{ minion.proxy | default(False) }}}

### 2. things needed for the following steps
{{ mname }} essentials:
  salt.state:
    - sls: init.essentials
    - tgt: {{ mname }}
    - pillar: {"proxy": {{ minion.proxy | default(False) }}}

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

### 4. install drivers, if needed
{{ mname }} install drivers:
  salt.state:
    - sls: drivers
    - tgt: {{ mname }}

### 5. networkmanager connections 
{{ mname }} nmconnections:
  salt.state:
    - sls: init.nmconnections
    - tgt: {{ mname }} 
    - pillar: {'interfaces': {{ minion.interfaces | default(False) }}}
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
{% set hoi = salt['cmd.run']("salt " + mname + " pillar.item highstate_on_init --out yaml") | load_yaml %}
{%- if hoi[mname]['highstate_on_init'] | default(True) %}

"-- {{ mname }} will execute high state":
  test.nop

# create a snapshot before the highstate
{{ mname }} create pre-highstate snapshot:
  salt.function:
    - name: virt.snapshot
    - tgt: {{ pillar.salt_server }}
    - kwarg: {'domain': {{ mname }}, 'name': 'pre-highstate', 'connection': '{{ pillar.virt.connection.url }}' }

{{ mname }} environment:
  salt.state:
    - sls: environment
    - tgt: {{ mname }}
    - pillar: {'map': {{ map }}}

'sleep 15s': cmd.run

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

# create a snapshot before enforcing cis-benchmark
{{ mname }} create pre-cis snapshot:
  salt.function:
    - name: virt.snapshot
    - tgt: {{ pillar.salt_server }}
    - kwarg: {'domain': {{ mname }}, 'name': 'pre-cis', 'connection': '{{ pillar.virt.connection.url }}' }

{{ mname }} cis enforce:
  salt.state:
    - sls: cis-benchmark
    - tgt: {{ mname }}
    - pillar: {'map': {{ map }}}
    
# waits (the previous state may restart salt-minion service)
{{ mname }} wait cis enforce:
  salt.wait_for_event:
    - name: salt/minion/*/start
    - id_list: [ '{{ mname }}' ]
    - timeout: 90
    - require:
      - salt: {{ mname }} cis enforce
{% else %}
"-- {{ mname }} will not execute high state":
  test.nop
{%- endif %}
