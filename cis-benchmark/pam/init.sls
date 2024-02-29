{% include "cis-benchmark/pam/" + grains['os'] | lower() + ".sls" ignore missing %}
