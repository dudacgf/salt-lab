{% include "cis-benchmark/" + grains['os'] | lower() + ".sls" ignore missing %}
