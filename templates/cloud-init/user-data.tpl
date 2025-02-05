#cloud-config
users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: [adm, sudo]
    shell: /bin/bash
    lock_passwd: true
    ssh_authorized_keys:
      - __REPLACE_ME__

disable_root: true
ssh_pwauth: no
manage_etc_hosts: true
preserve_hostname: false

runcmd:
  - cloud-init clean --logs --machine-id
  - dpkg-reconfigure openssh-server

final_message: "System initialized in $UPTIME seconds"
