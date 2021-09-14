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
  default = []
}

variable "auth_settings" {
  default = []
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

variable "cors" {
  default = []
}

variable "plan_tier" {
  type = string
  default = "Dynamic"
}

variable "plan_size" {
  type = string
  default = "Y1"
}