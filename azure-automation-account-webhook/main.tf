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

resource "azurerm_automation_account" "automation_account" {
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  name                = "auto-test-uks"
  sku_name            = "Free"
}

resource "azurerm_automation_runbook" "automation_account_runbook" {
  resource_group_name     = azurerm_resource_group.resource_group.name
  location                = azurerm_resource_group.resource_group.location
  automation_account_name = azurerm_automation_account.automation_account.name
  name                    = "HelloWorld"
  log_verbose             = "true"
  log_progress            = "true"
  runbook_type            = "PowerShell"
  publish_content_link {
    uri = "https://gist.githubusercontent.com/russmckendrick/fa422b292a786682da887643e72213d5/raw/c1b7aa3c9729b66341a25efbea75c961d2326df0/HelloWorld-Workflow.ps1"
  }
}

resource "time_rotating" "webhook_expiry_time" {
  rotation_years = 5
}
resource "random_string" "webhook_token1" {
  length  = 10
  upper   = true
  lower   = true
  number  = true
  special = false
}

resource "random_string" "webhook_token2" {
  length  = 31
  upper   = true
  lower   = true
  number  = true
  special = false
}

locals {
  webhook = "https://${split("/", azurerm_automation_account.automation_account.dsc_server_endpoint)[4]}.webhook.${substr(azurerm_resource_group.resource_group.location, 0, 3)}.azure-automation.net/webhooks?token=%2b${random_string.webhook_token1.result}%2b${random_string.webhook_token2.result}%3d"
}

resource "azurerm_template_deployment" "automation_account_webhook" {
  name                = "HelloWorldWebhook"
  resource_group_name = azurerm_resource_group.resource_group.name
  deployment_mode     = "Incremental"
  template_body       = <<DEPLOY
{
  "$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "resources": [
    {
      "name": "${azurerm_automation_account.automation_account.name}/HelloWorldWebhook",
      "type": "Microsoft.Automation/automationAccounts/webhooks",
      "apiVersion": "2015-10-31",
      "properties": {
        "isEnabled": true,
        "uri": "${local.webhook}",
        "expiryTime": "${time_rotating.webhook_expiry_time.rotation_rfc3339}",
        "parameters": {},
        "runbook": {
          "name": "${azurerm_automation_runbook.automation_account_runbook.name}"
        }
      }
    }
  ]
}
DEPLOY
}
