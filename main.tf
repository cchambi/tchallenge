# Configure the Microsoft Azure Provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
  
/*  backend "azurerm" {
    resource_group_name  = azurerm_resource_group.myterraformgroup.name
    storage_account_name = azurerm_storage_account.example.name
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
*/
  
}
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

locals {
  allowed_ip_ranges = [
    "190.238.151.40"
  ]
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "myterraformgroup" {
    name     = "myResourceGroup"
    location = "eastus"

    tags = {
        owner = "cchambi"
    }
}

resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "myVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = azurerm_resource_group.myterraformgroup.name

    tags = {
        owner = "cchambi"
    }
}

resource "azurerm_subnet" "myterraformsubnet" {
    name                 = "mySubnet"
    resource_group_name  = azurerm_resource_group.myterraformgroup.name
    virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
    address_prefixes       = ["10.0.1.0/24"]
    service_endpoints    = ["Microsoft.Storage","Microsoft.KeyVault"]
}

resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "myNetworkSecurityGroup"
    location            = "eastus"
    resource_group_name = azurerm_resource_group.myterraformgroup.name

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        owner = "cchambi"
    }
}

resource "azurerm_subnet_network_security_group_association" "example" {
    subnet_id = azurerm_subnet.myterraformsubnet.id
    network_security_group_id = azurerm_network_security_group.myterraformnsg.id
}

resource "azurerm_key_vault" "example" {
  name                        = "cchambikeyvault"
  location                    = azurerm_resource_group.myterraformgroup.location
  resource_group_name         = azurerm_resource_group.myterraformgroup.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name = "standard"

    network_acls {
    bypass = "AzureServices"
    default_action = "Deny"
    ip_rules = local.allowed_ip_ranges
    virtual_network_subnet_ids = [azurerm_subnet.myterraformsubnet.id]
    }
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get",
    ]

    storage_permissions = [
      "Get",
    ]
  }
}

resource "azurerm_storage_account" "example" {
  name                     = "examplestoraccount2"
  resource_group_name      = azurerm_resource_group.myterraformgroup.name
  location                 = azurerm_resource_group.myterraformgroup.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    owner = "cchambi"
  }
}

resource "azurerm_storage_container" "example" {
  name                  = "vhds"
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "private"
}

resource "azurerm_storage_account_network_rules" "test" {
  storage_account_id = azurerm_storage_account.example.id

  default_action             = "Deny"
  ip_rules                   = local.allowed_ip_ranges
  virtual_network_subnet_ids = [azurerm_subnet.myterraformsubnet.id]
  bypass = ["AzureServices"]
}
