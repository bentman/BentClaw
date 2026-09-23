#################### PROVIDERS ####################
# Define the required providers and Terraform version
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    # Provider for managing Azure resources
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    # Provider for generating the SSH key pair
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    # Provider for looking up the caller's public IP
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

# Configure the AzureRM provider with necessary credentials
provider "azurerm" {
  features {
    resource_group {
      # Prevent deletion of resource groups that contain resources
      prevent_deletion_if_contains_resources = false
    }
  }

  tenant_id       = var.arm_tenant_id
  subscription_id = var.arm_subscription_id
  client_id       = var.arm_client_id
  client_secret   = var.arm_client_secret
}