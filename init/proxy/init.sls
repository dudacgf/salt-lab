#
### 0. Proxy - defines proxy for apt/yum and salt-minion
#
{% set proxy = salt.cmd.run('salt ' + minion + ' pillar.get proxy') | load_yaml %}
{% if proxy != 'none' %}
{{ minion }} define proxy minion:
  salt.state:
    - sls: init.proxy.proxy_minion
    - tgt: {{ minion }}

# waits (the previous state restarts salt-minion service)
{{ minion }} proxy restart:
  salt.wait_for_event:
    - name: salt/minion/*/start
    - id_list: [ '{{ minion }}' ]
    - timeout: {{ pillar['sleep_a_longer_while'] }}
    - require:
      - salt: {{ minion }} define proxy

{{ minion }} define proxy syspkg:
  salt.state:
    - sls: init.proxy.proxy_syspkg
    - tgt: {{ minion }}

{% endif %}
