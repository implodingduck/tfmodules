variable "appname" {
  type = string
}

variable "tags" {
  type = map
  default = {}
}

variable "resource_group_name" {
  type = string
}

variable "resource_group_location" {
  type = string
}

variable "sku_tier" {
  type = string
  default = "Basic"
}

variable "sku_size" {
  type = string
  default = "B1"
}

variable "app_service_kind" {
  type = string
  default = "Linux"
}

variable "app_settings" {
  type = map
  default = {}
}

variable "site_config" {
  type = map
}

variable "workspace_id" {
  type = string
}