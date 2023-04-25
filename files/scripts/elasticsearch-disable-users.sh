#!/bin/bash

curl -k -s -u "elastic:{{ pillar['elasticsearch']['passwords']['elastic'] }}" -XPUT https://localhost:9200/_security/user/logstash_system/_disable
curl -k -s -u "elastic:{{ pillar['elasticsearch']['passwords']['elastic'] }}" -XPUT https://localhost:9200/_security/user/remote_monitoring_user/_disable
