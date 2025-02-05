#cloud-config
disable_root: true  # Отключает SSH доступ для root

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

runcmd:
  - cloud-init clean --logs --machine-id
