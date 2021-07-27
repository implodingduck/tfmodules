output "possible_outbound_ip_addresses" {
    value = split("," ,azurerm_function_app.func.possible_outbound_ip_addresses)
}