variable "name" {
    type = string
}
variable "location" {
  type = string
}

variable "vnet_cidr" {
    type = string 
    default = "10.16.0.0/22"
}

variable "default_subnet_cidr" {
    type = string 
    default = "10.16.0.0/24"
}

variable "vm_subnet_cidr" {
    type = string
    default = "10.16.1.0/24"
}

variable "num_vms" {
    type = number
    default = 2
}

variable "vm_size" {
    type = string
    default = "Standard_B2s"
}

variable "tags" {
    type = map
    default = {}
}

variable "env" {
    type = string 
    default = "sbx"
}
