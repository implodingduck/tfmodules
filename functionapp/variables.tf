variable "func_name" {
    type = string
}

variable "resource_group_name" {
  type = string
}

variable "resource_group_location" {
  type = string
}

variable "app_settings" {
  type = map
}

variable "app_identity" {
  type = map
  default = {}
}

variable "use_32_bit_worker_process" {
  type = bool
  default = false
}

variable "ftps_state" {
  type = string
  default = "Disabled"
}

variable "linux_fx_version" {
  type = string
  default = "Python|3.8"
}

variable "working_dir" {
  type = string
}