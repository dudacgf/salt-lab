###
#
## public_ip_dns_update - setups a cron job to run a script to dynamic 
#                         update public dns address
#

{%- for hostname in pillar.public_ddns | default ([ grains.host + '.' + grains.domain ]) %}
{%- set domain = '.'.join(hostname.split('.')[1:]) %}
{{ hostname }} copy ddns script:
  file.managed:
    - name: /usr/local/sbin/{{ pillar.dns_hoster_by_domain[domain] }}_dns_update.py
    - source: salt://files/scripts/{{ pillar.dns_hoster_by_domain[domain] }}_dns_update.py
    - user: root
    - group: root
    - mode: 750

{{ hostname }} cron updates:
  cron.present:
    - identifier: {{ hostname }} {{ pillar.dns_hoster_by_domain[domain] }}_dns_updates
    - name: /usr/local/sbin/{{ pillar.dns_hoster_by_domain[domain] }}_dns_update.py --hostname {{ hostname }} --zoneid {{ pillar[pillar.dns_hoster_by_domain[domain]][domain]['hosted_zone_id'] }}
    - minute: '*/5'
{%- endfor %}
