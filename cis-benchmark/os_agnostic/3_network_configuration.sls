####
#### Network Configuration
####

### 3.1 Disable unused network protocols and devices

## 3.1.1 Ensure system is checked to determine if IPv6 is enabled
## will not use ipv6. it will be disabled via sysctl
/etc/sysctl.d/62-ipv6-disable.conf:
  file.managed:
    - contents: |
          net.ipv6.conf.all.disable_ipv6 = 1
          net.ipv6.conf.default.disable_ipv6 = 1

## 3.1.2 Ensure wireless interfaces are disabled
disable wireless:
  cmd.script:
    - source: salt://cis-benchmark/scripts/wireless-off.sh
    - cwd: /root

## 3.1.3 Ensure TIPC is disabled 
/etc/modprobe.d/tipc.conf:
  file.managed:
    - contents: |
          install tipc /bin/true
          blacklist tipc

### 3.2 Network Parameters (Host)

## 3.2.1 Ensure packet redirect sending is disabled
/etc/sysctl.d/63_disable_packets_redirect.conf:
  file.managed:
    - contents: |
          net.ipv4.conf.all.send_redirects = 0
          net.ipv4.conf.default.send_redirects = 0

## 3.2.2 Ensure IP forwarding is disabled 
/etc/sysctl.d/64_disable_ip_forward.conf:
  file.managed:
    - contents: |
          net.ipv4.conf.all.ip_forward = 0
          net.ipv4.ip_forward = 0
          net.ipv6.conf.all.forwarding = 0

### 3.3 Network Parameters (Host and Router)

## 3.3.1 Ensure source routed packets are not accepted
/etc/sysctl.d/65_disable_source_routed_packets.conf:
  file.managed:
    - contents: |
          net.ipv4.conf.all.accept_source_route = 0
          net.ipv4.conf.default.accept_source_route = 0
          net.ipv6.conf.all.accept_source_route = 0
          net.ipv6.conf.default.accept_source_route = 0

## 3.3.2 Ensure ICMP redirects are not accepted
## 3.3.3 Ensure secure ICMP redirects are not accepted
## 3.3.5 Ensure broadcast ICMP requests are ignored 
## 3.3.6 Ensure bogus ICMP responses are ignored
/etc/sysctl.d/66_disable_icmp_problem_requests.conf:
  file.managed:
    - contents: |
          net.ipv4.conf.all.accept_redirects = 0
          net.ipv4.conf.default.accept_redirects = 0
          net.ipv6.conf.all.accept_redirects = 0
          net.ipv6.conf.default.accept_redirects = 0
          net.ipv4.conf.default.secure_redirects = 0
          net.ipv4.conf.all.secure_redirects = 0
          net.ipv4.icmp_echo_ignore_broadcasts = 1
          net.ipv4.icmp_ignore_bogus_error_responses = 1 

## 3.3.4 Ensure suspicious packets are logged 
/etc/sysctl.d/66_log_martians.conf:
  file.managed:
    - contents: |
          net.ipv4.conf.all.log_martians = 1
          net.ipv4.conf.default.log_martians = 1

## 3.3.7 Ensure Reverse Path Filtering is enabled 
/etc/sysctl.d/67_enable_reverse_path_filtering.conf:
  file.managed:
    - contents: |
          net.ipv4.conf.all.rp_filter = 1
          net.ipv4.conf.default.rp_filter = 1

## 3.3.8 Ensure TCP SYN Cookies is enabled 
/etc/sysctl.d/68_ensure_tcp_syn_cookies.conf:
  file.managed:
    - contents: |
          net.ipv4.tcp_syncookies = 1

## 3.3.9 Ensure IPv6 router advertisements are not accepted
/etc/sysctl.d/69_dont_accept_IPV6_router_advertisements.conf:
  file.managed:
    - contents: |
          net.ipv6.conf.all.accept_ra = 0
          net.ipv6.conf.default.accept_ra = 0

## load all sysctl
'sysctl --system > /dev/null': cmd.run

### 3.4 Uncommon Network Protocols

## 3.4.1 Ensure DCCP is disabled 
/etc/modprobe.d/dccp.conf:
  file.managed:
    - contents: | 
          blacklist dccp
          install dccp /bin/true


## 3.4.2 Ensure SCTP is disabled 
/etc/modprobe.d/sctp.conf:
  file.managed:
    - contents: | 
          blacklist sctp
          install sctp /bin/true

## 3.4.3 Ensure RDS is disabled
/etc/modprobe.d/rds.conf:
  file.managed:
    - contents: |
          blacklist rds
          install rds /bin/true

## 3.4.4 Ensure TIPC is disabled
## already done at 3.1.3
#/etc/modprobe.d/tipc.conf:
#  file.managed:
#    - contents: blacklist tipc

### 3.5 Firewall Configuration
{% include "environment/shorewall/init.sls" %}
# LOG_MARTIANS=Keep
shorewall log_martians keep:
  file.replace:
    - name: /etc/shorewall/shorewall.conf
    - pattern: '^LOG_MARTIANS=Yes$'
    - repl: 'LOG_MARTIANS=Keep'

