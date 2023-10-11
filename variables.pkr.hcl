variable "cluster" {
  type    = string
  default = ""
}

variable "datastore" {
  type    = string
  default = ""
}

variable "host" {
  type    = string
  default = ""
}

variable "folder" {
  type    = string
  default = ""
}

variable "network" {
  type    = string
  default = ""
}

variable "ssh_username" {
  type    = string
  default = ""
}

variable "ssh_password" {
  type    = string
  default = ""
}

variable "username" {
  type    = string
  default = ""
}

variable "password" {
  type    = string
  default = ""
}

variable "vcenter_server" {
  type    = string
  default = ""
}

variable "vm_name" {
  type    = string
  default = ""
}

variable "datacenter" {
  type    = string
  default = ""
}

variable "vm_dns" {
  type    = string
  default = ""
}

variable "gateway" {
  type    = string
  default = ""
}

variable "cloudinit_dir" {
  type    = string
  default = ""
}

variable "content_library" {
  type    = string
  default = ""
}

variable "template_name" {
  type    = string
  default = "thepackman"
}