###
## Creates a list of vms, initializes them and runs its first highstate 
#
#  You should call this as a orchestration, passing the name of the minions as a pillar:
#
#  sudo salt-run state.orch init 
# 
#  the vms will be created from the values instated in the minions pillar field of
#  the global virtual_host pillar value. the format of the minions pillar is
#
#         {minions: {1: {'name': m1, 'profile': p1}, 2: {'name': ...} }
#  the order of minion creation and configuration is defined by the number in the pillar
#
#  the following pillar fields are used:
#  virtual_host: id of the virtual host where the VMs will be created
#  virt_provider: name of a provider as defined in cloud.providers.d/libvirt.conf
#
#  (c) ecgf - set/2023
#

# get list of minions from map
{% set map = pillar['map'] | default('lab_minions') %}
{% import_yaml 'maps/' + map + '.yaml' as minions %}
# get list of existing vms in vm host pillar['virtual_host'] 
{% set vhost_vmlist = salt['cmd.run']("salt " + pillar['virtual_host'] + " virt.list_domains") | 
                      default(pillar['virtual_host']) | load_yaml %}

#
### loop through list of minions creating and configuring each one
{% for minion in minions | default([]) %}
{% set mname = minion.name %}

### if vm does not exists yet, create it
{% if mname not in vhost_vmlist[pillar['virtual_host']] %}

{{ mname }} create_instance:
  salt.runner:
    - name: cloud.profile
    - provider: {{ minion.virtual_provider }}
    - prof: {{ minion.profile | default('debian_gold') }}
    - instances:
      - {{ mname }}
    - opts:
      - clone_stratety: full
    - quiet: true

{% endif %}

### redefines interfaces, if needed
{{ mname }} redefine interfaces:
  salt.state:
    - sls: init.redefine_interfaces
    - tgt: {{ minion.virtual_host | default(grains['id']) }}
    - pillar: {'minion': {{ mname }}, 'redefine_interfaces': {{ minion.redefine_interfaces | default(False) }}, 'minion_interfaces': {{ minion.interfaces | default({}) }} }

# wait (add minion interfaces restarts salt-minion service)
{{ mname }} wait interfaces:
  salt.wait_for_event:
    - name: salt/minion/*/start
    - id_list: [ "{{ mname }}" ]
    - timeout: 120
    - require:
      - salt: {{ mname }} redefine interfaces

### attach usb devices
{{ mname }} attach usb devices:
  salt.state:
    - sls: init.attach_usb
    - tgt: {{ minion.virtual_host | default(grains['id']) }}
    - pillar: {'minion': {{ mname }}, 'usb_devices': {{ minion.usb_devices | default(None) }}}

### configures the minion
{% set temp = '{"1": ' + minion | tojson + '}' %}
{% set pillar_minion = '{"minions": ' + temp + '}' %}

{{ mname }} call config:
  salt.runner:
    - name: state.orchestrate
    - mods: init.config
    - pillar: {{ pillar_minion }}

{% endfor %}
