terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "RG-Terraform"
  location = "westeurope"
  tags = {
    Environment = "Terraform Getting Started"
    Team = "DevOps"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "VNet-Terraform"
  address_space       = ["10.0.0.0/16"]
  location            = "westeurope"
  resource_group_name = azurerm_resource_group.rg.name
  tags = {
    Environment = "Terraform Getting Started"
    Team = "DevOps"
    Demo = "Manolo Cabeza Gorda"
  }
}