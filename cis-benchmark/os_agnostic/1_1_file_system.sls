### 1.1 File System Configuration

## 1.1.1 Disable filesystems not secure
/etc/modprobe.d/cramfs.conf:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents: |
          install cramfs /bin/true
          blacklist cramfs

/etc/modprobe.d/freevxfs.conf:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents: |
          install freevxfs /bin/true
          blacklist freevxfs

/etc/modprobe.d/jffs2.conf:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents: |
          install jffs2 /bin/true
          blacklist jffs2

/etc/modprobe.d/hfs.conf:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents: |
          install hfs /bin/true
          blacklist hfs

/etc/modprobe.d/hfsplus.conf:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents: |
          install hfsplus /bin/true
          blacklist hfsplus

/etc/modprobe.d/squashfs.conf:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents: |
          install squashfs /bin/true
          blacklist squashfs

/etc/modprobe.d/udf.conf:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents: |
          install udf /bin/true
          blacklist udf

### 1.1 Partitioning
## 1.1.2/1.1.3/1.1.4/1.1.5. /tmp in a separated partition nosuid,noexec,nodev
## 1.1.6/1.1.7/1.1.8/1.1.9  /dev/shm in a separated partition nosuid,noexec,nodev
## 1.1.11/1.1.12/1.1.13/1.1.14  /var/tmp in a separeted partition nosuid,noexec,nodev

/etc/fstab:
  file.append:
    - text: |
        tmpfs    /tmp        tmpfs	defaults,noexec,nodev,nosuid,size=2G	0	0
        tmpfs    /dev/shm    tmpfs	defaults,noexec,nodev,nosuid,size=2G	0	0
        tmpfs    /var/tmp    tmpfs	defaults,noexec,nodev,nosuid,size=2G	0	0

# 1.1.17/1.1.19/1.1.20/1.1.21 Separated partition to /home as nosuid,noexec,nodev
# the partition should be separated when creating the base image
nosuid_home:
  file.replace:
    - name: /etc/fstab
    - pattern: '\/home\s*(.*)\s*defaults'
    - repl: '/home   	\1 rw,nodev,noexec,nosuid'

# 1.1.10/10.1.18 Separated partition to /var as nodev,nosuid
# the partition should be separated when creating the base image
nosuid_var:
  file.replace:
    - name: /etc/fstab
    - pattern: '\/var\s+(.*)\s*defaults'
    - repl: '/var   	\1 rw,nodev,nosuid'

# 1.1.15 Separated partition to /var/log as nodev,nosuid,noexec
# the partition should be separated when creating the base image
nosuid_var_log:
  file.replace:
    - name: /etc/fstab
    - pattern: '\/var/log\s+(.*)\s*defaults'
    - repl: '/var/log   	\1 rw,nodev,nosuid,noexec'

# 1.1.16 Separated partition to /var/log/audit as nodev,nosuid,noexec
# the partition should be separated when creating the base image
nosuid_var_log_audit:
  file.replace:
    - name: /etc/fstab
    - pattern: '\/var/log/audit\s+(.*)\s*defaults'
    - repl: '/var/log/audit   	\1 rw,nodev,nosuid,noexec'

# 1.1.22 Ensure sticky bit is set on all world-writable directories. 
# covered at cis-benchmark.os_agnostic.6_file_permissions 6.1.12

# 1.1.23 Disable autofs service
autofs:
  service.disabled

# 1.1.24 Disable USB Storage
/etc/modprobe.d/usb_storage.conf:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents: |
          install usb-storage /bin/true
          blacklist usb-storage
