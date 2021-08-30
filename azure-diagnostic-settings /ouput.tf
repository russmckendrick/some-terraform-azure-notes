output "metrics" {
  value = data.azurerm_monitor_diagnostic_categories.vnet.metrics
}

output "logs" {
  value = data.azurerm_monitor_diagnostic_categories.vnet.logs
}
