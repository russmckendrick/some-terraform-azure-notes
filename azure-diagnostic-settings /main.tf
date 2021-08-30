terraform {
  required_version = ">= 1.0.0"
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm" # https://registry.terraform.io/providers/hashicorp/azurerm/latest
    }
  }
}

provider "azurerm" { # Configure the Microsoft Azure RM Provider
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}


resource "azurerm_resource_group" "resource_group" {
  name     = "rg-test-uks"
  location = "uksouth"
}

resource "azurerm_log_analytics_workspace" "monitor" {
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  name                = "law-test"
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_virtual_network" "vnet" {
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  name                = "vnet-test-001"
  address_space       = ["192.168.0.0/16"]
}

resource "azurerm_subnet" "subnet_001" {
  resource_group_name  = azurerm_resource_group.resource_group.name
  name                 = "snet-app-001"
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["192.168.10.0/24"]
}

data "azurerm_monitor_diagnostic_categories" "vnet" {
  resource_id = azurerm_virtual_network.vnet.id
}

resource "azurerm_monitor_diagnostic_setting" "vnet" {
  name                       = "diag-${azurerm_virtual_network.vnet.name}"
  target_resource_id         = azurerm_virtual_network.vnet.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.monitor.id

  dynamic "log" {
    for_each = data.azurerm_monitor_diagnostic_categories.vnet.logs
    content {
      category = log.value
      retention_policy {
        days    = 0
        enabled = false
      }
    }
  }

  dynamic "metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.vnet.metrics
    content {
      category = metric.value
      retention_policy {
        days    = 0
        enabled = false
      }
    }
  }
}