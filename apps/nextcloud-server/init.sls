#
## nextcloud.sls - instala e configura uma instância de nextcloud
#
# ecgf - nov/2022
#

{% if grains['os_family'] != 'RedHat' %}
nextcloud failure:
  test.fail_without_changes:
    - name: '** OS not supported yet **'
    - failhard: True
{% endif %}
  

include:
  - apps.nextcloud-server.php_additional
  - apps.nextcloud-server.nextcloud_install
  - apps.nextcloud-server.nextcloud_config
  - apps.nextcloud-server.apache_config
  - apps.nextcloud-server.nextcloud_selinux
