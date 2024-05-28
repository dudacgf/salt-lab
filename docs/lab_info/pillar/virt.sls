### salt-master has ssh private key to access libvirt server
virt:
  connection:
    driver: libvirt
    url: qemu+ssh://root@192.168.100.1/system?socket=/var/run/libvirt/libvirt-sock
    validate_xml: no
