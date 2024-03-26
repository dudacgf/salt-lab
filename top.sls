base:
  '*': 
    - environment
    - basic_services
    - services
    - roles
    - apps
    - pkgs
  'cis:enforced':
    - match: pillar
    - cis-benchmark
 
