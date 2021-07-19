variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "resource_group_location" {
  type = string
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "tags" {
    type = map
    default = {}
}
