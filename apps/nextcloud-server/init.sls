#
## nextcloud.sls - instala e configura uma instância de nextcloud
#
# ecgf - nov/2022
#

{% if grains['os_family'] not in ['RedHat', 'Debian'] %}
nextcloud failure:
  test.fail_without_changes:
    - name: '** OS not supported yet **'
    - failhard: True
{% else %}
{%- import_yaml "maps/pkg_data/by_os_family.yaml" as pkg_data %}
{%- set pkg_data = salt.grains.filter_by(pkg_data) %}

{% include "apps/nextcloud-server/php_additional.sls" %}
{% include "apps/nextcloud-server/nextcloud_install.sls" %}
{% include "apps/nextcloud-server/nextcloud_config.sls" %}
{% include "apps/nextcloud-server/apache_config.sls" %}
{% include "apps/nextcloud-server/nextcloud_selinux.sls" %}
{% endif %}
