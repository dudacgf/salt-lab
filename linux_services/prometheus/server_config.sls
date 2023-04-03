#
# diretorio onde colocaremos os targets 
/etc/prometheus/targets.d:
  file.directory:
    - user: prometheus
    - group: prometheus
    - dir_mode: 755

#
# patch para apontar para esse diretório
add_targets.d_scrape:
  file.patch:
    - name: /etc/prometheus/prometheus.yml
    - source: salt://files/services/prometheus/prometheus.yml.patch
    - require:
      - /etc/prometheus/targets.d

prometheus:
  service.running:
    - enable: true
    - restart: true
    - watch: 
      - file: /etc/prometheus/prometheus.yml
      - file: /etc/prometheus/target.d
