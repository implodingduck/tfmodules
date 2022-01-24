resource "azurerm_subscription" "msdn" {
  alias             = var.alias
  subscription_name = var.subscription_name
  subscription_id   = var.subscription_id
}