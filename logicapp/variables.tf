variable "name" {
    type = string
}

variable "resource_group_name" {
  type = string
}

variable "resource_group_location" {
  type = string
}

variable "subnet_id_logicapp" {
  type = string
}

variable "subnet_id_pe" {
  type = string
}

variable "tags" {
  type = object
}