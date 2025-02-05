source "qemu" "ubuntu" {
  iso_url           = "https://cloud-images.ubuntu.com/minimal/releases/noble/release/ubuntu-24.04-minimal-cloudimg-amd64.img"
  iso_checksum      = "file:https://cloud-images.ubuntu.com/minimal/releases/noble/release/SHA256SUMS"
  disk_image        = true
  output_directory  = "output"
  disk_size         = "20G"
  format            = "qcow2"
  accelerator       = "tcg"
  
  # SSH настройки
  ssh_username      = "ubuntu"
  ssh_private_key_file = "./packer-key"
  ssh_agent_auth    = false
  ssh_timeout       = "15m"

  # Настройки VM
  memory           = "2048"
  cpus             = "2"
  
  # Cloud-init настройки
  cd_files         = ["./cloud-init/meta-data", "./cloud-init/user-data"]
  cd_label         = "cidata"

  qemuargs = [
    ["-display", "none"],
    ["-serial", "mon:stdio"],
  ]

  display          = "none"
  headless         = true
}

build {
  sources = ["source.qemu.ubuntu"]

  provisioner "shell" {
    environment_vars = [
       "DEBIAN_FRONTEND=noninteractive",
       "LC_ALL=C",
       "LANG=en_US.UTF-8"
    ]

    inline = [
      "# Обновляем систему и устанавливаем базовые утилиты",
      "sudo apt-get update",
      "sudo apt-get install -y curl vim net-tools",
      "sudo apt-get clean",
      "sudo rm -rf /var/lib/apt/lists/*",
    ]
  }
}
