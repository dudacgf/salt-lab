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

#
### 0. Proxy - defines proxy for apt/yum and salt-minion
#
{% set proxy = salt.cmd.run('salt ' + minion + ' pillar.get proxy') | load_yaml %}
{% if 'proxy' != 'none' %}
{{ minion }} define proxy:
  salt.state:
    - sls: init.proxy
    - tgt: {{ minion }}

# waits (the previous state restarts salt-minion service)
{{ minion }} proxy restart:
  salt.wait_for_event:
    - name: salt/minion/*/start
    - id_list: [ '{{ minion }}' ]
    - timeout: {{ pillar['sleep_a_longer_while'] }}
    - require:
      - salt: {{ minion }} define proxy
{% else %}
no proxy:
  test.nop:
    - name: '=== no proxy ==='
{% endif %}

#
### 1. things needed for the following steps
#

{{ minion }} essentials:
  salt.state:
    - sls: init.essentials
    - tgt: {{ minion }}

# waits (essentials restarts the minion service)
{{ minion }} wait restart:
  salt.wait_for_event:
    - name: salt/minion/*/start
    - id_list: [ '{{ minion }}' ]
    - timeout: 240
    - require:
      - salt: {{ minion }} essentials

#
### 2. os_specific initialization (repos, yum/apt settings etc)
{{ minion }} os_specific:
   salt.state:
     - sls: init.os_specific
     - tgt: {{ minion }}

#
### 3. NetworkManager
{{ minion }} network manager:
  salt.state:
    - sls: init.networkmanager
    - tgt: {{ minion }}

# waits (Network Manager state reboots the minion if needed)
{{ minion }} network manager reboot:
  salt.wait_for_event:
    - name: salt/minion/*/start
    - id_list: [ '{{ minion }}' ]
    - timeout: 240
    - require:
      - salt: {{ minion }} network manager
    - onlyif:
      - fun: match.grain
        tgt: "!os_family:RedHat"
#
#
### 4. if host pillar defines interfaces, create them in the virtual_host and set it's ip address
#
{% set redefine_interfaces = salt.cmd.run('salt ' + minion + 
                                          ' pillar.get redefine_interfaces') | load_yaml %}
{% if redefine_interfaces[minion] %}

#
## adds the network virtual interfaces to the minion (this is run in the virtual_host)
{% set interfaces = salt['cmd.run']("salt " + minion + " pillar.get interfaces") | load_yaml %}
{{ minion }} add interfaces:
  salt.state:
    - sls: init.add_minion_interfaces
    - tgt: {{ pillar['virtual_host'] }}
    - pillar: {'minion_interfaces': {{ interfaces[minion] }}, 'minion': {{ minion }} }

#
## wait (add minion interfaces reboots the minion)
{{ minion }} aguarda interfaces:
  salt.wait_for_event:
    - name: salt/minion/*/start
    - id_list: [ "{{ minion }}" ]
    - timeout: 360 ## TODO diminuir isso aqui
    - require:
      - salt: {{ minion }} add interfaces

#
## configures static ip for the new interfaces (if needed)
{{ minion }} set extra ips:
  salt.state:
    - sls: init.setextraips
    - tgt: {{ minion }} 
    - timeout: 30
    - require:
      - salt: {{ minion }} add interfaces

#
## waits (setextraips reboots the minion)
{{ minion }} aguarda extra ips:
  salt.wait_for_event:
    - name: salt/minion/*/start
    - id_list: [ "{{ minion }}" ]
    - timeout: 120 ## TODO diminuir isso aqui
    - require:
      - salt: {{ minion }} set extra ips
    - onlyif: 
      - fun: match.grain
        tgt: 'flag_static_extra_ips_set:True'

{% else %}

#
### 5. sets static ip if configured in the minion host pillar
#
{{ minion }} static ip:
  salt.state:
    - sls: init.setipaddress
    - tgt: {{ minion }}

# waits (setipaddress restarts salt-minion service)
{{ minion }} aguarda restart:
  salt.wait_for_event:
    - name: salt/minion/*/start
    - id_list: [ '{{ minion }}' ]
    - timeout: 30
    - require:
      - salt: {{ minion }} static ip
{% endif %}

{#
### 6. executa o highstate desse minion
{{ minion }} highstate:
  salt.state:
    - tgt: {{ minion }}
    - highstate: True

#}
{% endfor %} # minion in...
