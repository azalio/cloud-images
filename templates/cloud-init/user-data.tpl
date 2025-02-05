#cloud-config
users:
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: [adm, sudo]
    shell: /bin/bash
    lock_passwd: true
    ssh_authorized_keys:
      - __REPLACE_ME__

disable_root: true  # Отключает SSH доступ для root
ssh_pwauth: no
manage_etc_hosts: true
preserve_hostname: false
package_update: true
package_upgrade: true
packages:
  - curl
  - ca-certificates

runcmd:
  - cloud-init status --wait
  - cloud-init clean --logs --machine-id
  - dpkg-reconfigure openssh-server
  - reboot
final_message: "System initialized in $UPTIME seconds"
