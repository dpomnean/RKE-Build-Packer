packer {
  required_plugins {
    vsphere = {
      version = ">= v1.1.1"
      source  = "github.com/hashicorp/vsphere"
    }
  }
}

source "vsphere-iso" "ubuntu-2204" {
  guest_os_type        = "ubuntu64Guest"
  RAM                  = 8192
  CPUs                 = 4
  boot_order           = "disk,cdrom"
  cluster              = var.cluster
  convert_to_template  = false
  datastore            = var.datastore
  datacenter           = var.datacenter
  disk_controller_type = ["pvscsi"]
  host                 = var.host
  folder               = var.folder
  iso_url              = "https://releases.ubuntu.com/jammy/ubuntu-22.04.1-live-server-amd64.iso"
  iso_checksum         = "10f19c5b2b8d6db711582e0e27f5116296c34fe4b313ba45f9b201a5007056cb"

  insecure_connection = true
  username            = var.username
  password            = var.password
  vcenter_server      = var.vcenter_server
  vm_name             = var.vm_name

  content_library_destination {
    library   = var.content_library
    name      = var.template_name
    destroy   = true
    datastore = var.datastore
    ovf       = true
  }

  network_adapters {
    network      = var.network
    network_card = "vmxnet3"
  }

  storage {
    disk_size             = 50000
    disk_thin_provisioned = true
  }

  ssh_password           = var.ssh_password
  ssh_username           = var.ssh_username
  ssh_handshake_attempts = "50"
  ssh_timeout            = "1h"
  boot_wait              = "5s"
  cd_files = [
    "./http/${var.cloudinit_dir}/meta-data",
  "./http/${var.cloudinit_dir}/user-data"]

  cd_label = "cidata"

  boot_command = [
    "c",
    "linux /casper/vmlinuz autoinstall quiet ---",
    "<enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>"
  ]
}

build {
  sources = [
    "source.vsphere-iso.ubuntu-2204"
  ]
  provisioner "file" {
    source      = "./scripts/script_rke2.sh"
    destination = "/tmp/script_rke2.sh"
  }
  provisioner "shell" {
    execute_command = "echo '${var.ssh_password}' | sudo -S -E bash '{{.Path}}'"

    inline = [
      "chmod u+x /tmp/script_rke2.sh",
      "/tmp/script_rke2.sh ${var.gateway}"
    ]
  }
}
