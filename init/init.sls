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

# get list of minions from virtual_host pillar
{% set minions = salt['cmd.run']("salt " + pillar['virtual_host'] + " pillar.item minions ") | load_yaml %}
{% set minions = minions[pillar['virtual_host']]['minions'] %}

# get list of existing vms in vm host pillar['virtual_host'] 
{% set vhost_vmlist = salt['cmd.run']("salt " + pillar['virtual_host'] + " virt.list_domains") | 
                      default(pillar['virtual_host']) | load_yaml %}


{% for minion in minions | default([]) %}
{% set mname = minions[minion]['name'] %}
{% set profile = minions[minion]['profile'] %}

### if vm does not exists yet, create it
{% if mname not in vhost_vmlist[pillar['virtual_host']] %}

{{ mname }} create_instance:
  salt.runner:
    - name: cloud.profile
    - provider: {{ pillar['virt_provider'] }}
    - prof: {{ profile }}
    - instances:
      - {{ mname }}
    - opts:
      - clone_stratety: full
    - quiet: true

{% endif %}

### configures the minion
{% set temp = '{"1": ' + minions[minion] | tojson + '}' %}
{% set pillar_minion = '{"minions": ' + temp + '}' %}

{{ mname }} call config:
  salt.runner:
    - name: state.orchestrate
    - mods: init.config
    - pillar: {{ pillar_minion }}
{% endfor %}
