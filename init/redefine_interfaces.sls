#
## add_minions_interfaces.sls - adiciona interfaces de rede a um ou mais minions
#

{% if pillar['redefine_interfaces'] | default(False) %}

# which minion to apply interfaces to 
{% set minion = pillar['minion'] %}

# the interfaces to be applied to the minion
# TODO: this should be a _utils module but 
{% set interfaces = pillar['minion_interfaces'] %}
{% set interface_list = [] %}
{% for interface in interfaces %}

    {% set itype  = interfaces[interface]['itype'] | default('network') %}
    {% if itype != 'hotspot' %}
        {% set hwaddr = interfaces[interface]['hwaddr'] | default(False) %}
        {% if hwaddr %}
           {% do interface_list.append("{'name': '" + interface + "', 'mac': '" + hwaddr + "', 'source': '" + interface + "', 'type': '" + itype + "'}") %}
        {% else %}
           {% do interface_list.append("{'name': '" + interface + "', 'source': '" + interface + "', 'type': '" + itype + "'}") %}
        {% endif %}
    {% endif %}

{% endfor %}

# aplica a lista de interface
redefine interfaces:
  virt.defined:
    - name: {{ minion }}
    - interfaces: [ {{ interface_list | join(',') }} ]

stopped:
  virt.stopped:
    - name: {{ minion }}

sleep a while:
  cmd.run:
    - name: 'sleep {{ pillar['sleep_a_while'] | default(15) }}'
    - require:
      - virt:  stopped

started:
  virt.running:
    - name: {{ minion }}
    - require:
      - virt:  stopped

{% else %}

"salt/minion/{{ grains['id'] }}/start":
  event.send:
    - data: '-- no interfaces will be added/redefined to {{ pillar['minion'] }}.'
{% endif %}
