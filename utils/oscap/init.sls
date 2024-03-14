#
## utils.oscap.init - orchestrate a cis/csa oscap eval in a minion and copy
#                     results to lduda://var/www/html/[minion_id]_scan_report.html
#

{% set minion = pillar.minion %}
{% set os_grain = salt.cmd.run('salt ' + minion + ' grains.item os --out yaml') | load_yaml%}
{% set os_minion = os_grain[minion]['os'] | lower %}

"{{ os_minion }}": test.nop
run oscap:
  salt.state:
    - sls: utils.oscap.{{ os_minion }}
    - tgt: {{ minion }}

mkdir -p /var/cache/salt/master/minions/{{ minion }}/files: cmd.run

get oscap report:
  salt.function:
    - name: cp.push
    - tgt: {{ minion }}
    - kwarg: {'path': '/tmp/scan_report.html'}

get oscap results:
  salt.function:
    - name: cp.push
    - tgt: {{ minion }}
    - kwarg: {'path': '/tmp/scan_results.xml'}

cp /var/cache/salt/master/minions/{{ minion }}/files/tmp/scan_report.html /srv/local/tmp: cmd.run

send oscap report:
  salt.state:
    - sls: utils.oscap.send_oscap
    - tgt: {{ pillar['virtual_host'] }}
    - pillar: {'minion': {{ minion }} } 
     
python3 /srv/salt/utils/oscap/get_oscap_score.py --file /var/cache/salt/master/minions/cis/files/tmp/scan_results.xml: cmd.run

