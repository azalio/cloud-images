variable "ubuntu_version" {
  default = "24.04"
}

variable "ubuntu_codename" {
  default = "noble"
}

source "qemu" "ubuntu" {
  iso_url           = "https://cloud-images.ubuntu.com/minimal/releases/${var.ubuntu_codename}/release/ubuntu-${var.ubuntu_version}-minimal-cloudimg-amd64.img"
  iso_checksum      = "file:https://cloud-images.ubuntu.com/minimal/releases/${var.ubuntu_codename}/release/SHA256SUMS"
  disk_image        = true
  output_directory  = "output"
  disk_size         = "20G"
  format            = "qcow2"
  accelerator       = "tcg"
  disk_compression  = true

  ssh_username      = "ubuntu"
  ssh_private_key_file = "./packer-key"
  ssh_agent_auth    = false
  ssh_timeout       = "15m"

  memory           = "4096"
  cpus             = "4"
  
  
  cd_files         = ["./cloud-init/meta-data", "./cloud-init/user-data"]
  cd_label         = "cidata"

  qemuargs = [
    ["-display", "none"],
    ["-serial", "mon:stdio"],
    ["-nodefaults"],
  ]

  display          = "none"
  headless         = true
}

build {
  name = "cilium-base-image"
  sources = ["source.qemu.ubuntu"]

  provisioner "shell" {
    environment_vars = [
       "DEBIAN_FRONTEND=noninteractive",
       "LC_ALL=C",
       "LANG=en_US.UTF-8"
    ]
    script = "scripts/provision.sh"
  }
}
