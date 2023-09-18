# which minion to apply interfaces to 
{% set minion = pillar['minion'] %}

{{ minion }} stopped:
  virt.stopped:
    - name: {{ minion }}

{{ minion }} sleep a while:
  cmd.run:
    - name: 'sleep {{ pillar['sleep_a_while'] | default(15) }}'
    - require:
      - virt: {{ minion }} stopped

{{ minion }} running:
  virt.running:
    - name: {{ minion }}
    - require: 
      - virt: {{ minion }} stopped

