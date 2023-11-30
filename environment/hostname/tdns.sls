{% set hostname = grains['id'].split('.')[0] %}
{% set domain_type = pillar['location'] %}
{% set domain = pillar[domain_type + '_domain'] %}
{% set tdns_user = pillar['tdns_hosting']['tdns_user'] %}
{% set tdns_password = pillar['tdns_hosting']['tdns_pw'] %}
{% set tdns_server = pillar['tdns_hosting']['server'] %}
{% set ip4_address = grains.ipv4 | difference(['127.0.0.1']) | first %}

{% set tokenName = salt.random.get_str(10,printable=False,punctuation=False,whitespace=False) %}
{% set response = salt.http.query(url='https://' + tdns_server + '/api/user/createToken?user=' + tdns_user + '&pass=' + 
                                       tdns_password + '&tokenName=' + tokenName, method='GET') | tojson %}

{% set jr = response | load_json %}
{% set body = jr['body'] | load_json %}

{% if body['status'] == 'ok' %}
    {% set token = body['token'] %}
register host:
  module.run:
    - http.query:
      - url: 'https://{{ tdns_server }}/api/zones/records/add?token={{ token }}&domain={{ hostname }}.{{ domain }}&zone={{ domain }}&type=A&ipAddress={{ ip4_address }}'
{% else %}
'-- could not get a api token from tdns server.':
  test.nop
{% endif %}
