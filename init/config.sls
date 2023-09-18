###
## Initializes networks and runs first highstate for a group of minions
#
#  You should call this as a orchestration, passing the name of the minions as a pillar:
#
#  sudo salt-run state.orch init pillar='{minions: [m1, m2, m3...]}'
#
#  (c) ecgf - mar/2023
#

{% import "utils/macros.sls" as m %}

{% for minion in pillar['minions'] | default([]) %}
{% set mname = pillar['minions'][minion]['name'] %}

#
### 0. Proxy - defines proxy for apt/yum and salt-minion
#

{% set proxy = salt.cmd.run('salt ' + mname + ' pillar.get proxy') | load_yaml %}
{% if proxy[mname] != 'none' %}
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

{% else %}
{{ mname }} no proxy:
  test.nop:
    - name: '=== no proxy ==='
{% endif %}

#
### 1. os_specific initialization (repos, yum/apt settings etc)
{{ mname }} os_specific:
   salt.state:
     - sls: init.os_specific
     - tgt: {{ mname }}

#
### 2. things needed for the following steps
#
{{ m.wait_minion(mname, 'b_es') }}

{{ mname }} essentials:
  salt.state:
    - sls: init.essentials
    - tgt: {{ mname }}

# waits (essentials restarts the minion service)
{{ mname }} wait restart:
  salt.wait_for_event:
    - name: salt/minion/*/start
    - id_list: [ '{{ mname }}' ]
    - timeout: 240
    - require:
      - salt: {{ mname }} essentials

#
### 3. NetworkManager
{{ mname }} network manager:
  salt.state:
    - sls: init.networkmanager
    - tgt: {{ mname }}

# waits (Network Manager state reboots the minion if needed)
{{ mname }} network manager reboot:
  salt.wait_for_event:
    - name: salt/minion/*/start
    - id_list: [ '{{ mname }}' ]
    - timeout: 240
    - require:
      - salt: {{ mname }} network manager
    - onlyif:
      - fun: match.grain
        tgt: "!os_family:RedHat"
#
#
### 4. if host pillar defines interfaces, create them in the virtual_host and set it's ip address
#
#
## adds the network virtual interfaces to the minion (this is run in the virtual_host)
{% set interfaces = salt['cmd.run']("salt " + mname + " pillar.get interfaces") | load_yaml %}
{% if interfaces[mname]['redefine'] %}

{% do interfaces[mname].pop('redefine') %}
{{ mname }} add interfaces:
  salt.state:
    - sls: init.add_minion_interfaces
    - tgt: {{ pillar['virtual_host'] }}
    - pillar: {'minion_interfaces': {{ interfaces[mname] }}, 'minion': {{ mname }} }

#
## wait (add minion interfaces reboots the minion)
{{ mname }} aguarda interfaces:
  salt.wait_for_event:
    - name: salt/minion/*/start
    - id_list: [ "{{ mname }}" ]
    - timeout: 360 ## TODO diminuir isso aqui
    - require:
      - salt: {{ mname }} add interfaces

#
## configures static ip for the new interfaces (if needed)
{{ m.wait_minion(mname, 'b-ei') }}
{{ mname }} set extra ips:
  salt.state:
    - sls: init.setextraips
    - tgt: {{ mname }} 
    - timeout: 30
    - require:
      - salt: {{ mname }} add interfaces

#
## restarts minion via its virtual host server
{{ mname }} restart virtual guest:
  salt.state:
    - sls: utils.stops_starts_virtual_guest
    - tgt: {{ pillar['virtual_host'] }}
    - pillar: {'minion': {{ mname }}}

{{ m.wait_minion(mname, 'a-ei') }}
#
## if redefine_proxy is set, redefine proxy
{% set proxy = salt.cmd.run('salt ' + mname + ' pillar.get redefine_proxy') | load_yaml %}

{% if proxy[mname] != 'none' %}
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

{% else %}
no redefine proxy:
  test.nop:
    - name: '=== no redefine proxy ==='
{% endif %}



{% else %}
#
### 5. sets static ip if configured in the minion host pillar
#
{{ mname }} static ip:
  salt.state:
    - sls: init.setipaddress
    - tgt: {{ mname }}

# waits (setipaddress restarts salt-minion service)
{{ mname }} aguarda restart:
  salt.wait_for_event:
    - name: salt/minion/*/start
    - id_list: [ '{{ mname }}' ]
    - timeout: 30
    - require:
      - salt: {{ mname }} static ip
{% endif %}


### 6. executa o highstate desse minion
{% set hoi = salt['cmd.run']("salt " + mname + " pillar.item highstate_on_init") | load_yaml %}
{%- if hoi[mname]['highstate_on_init'] | default(False) %}

## aguarda minion voltar ao ar
{{ m.wait_minion(mname, 'b-hs') }}

"{{ mname }} === will execute high state ===":
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
"{{ mname }} === will not execute high state ===":
  test.nop
{%- endif %}

{% endfor %} # minion in...
