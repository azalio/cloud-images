#cloud-config
users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: users, admin
    shell: /bin/bash
    lock_passwd: true
    ssh_authorized_keys:
      - __REPLACE_ME__

ssh_pwauth: false

ssh:
  password_auth: false
  
manage_etc_hosts: true
preserve_hostname: false

packages:
  - cloud-utils

runcmd:
  - cloud-init clean --logs --machine-id
  - rm -f /etc/ssh/ssh_host_*
  - dpkg-reconfigure openssh-server
  - echo "Waiting for cloud-init to complete..."
  - cloud-init status --wait
