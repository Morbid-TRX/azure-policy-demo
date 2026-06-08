# Configure the Azure provider plugin
# Using environment variables for auth (ARM_TENANT_ID, ARM_SUBSCRIPTION_ID)
# instead of hardcoding credentials — security best practice
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  # Remote state backend — stores tfstate in Azure Blob Storage
  # Prevents state file from living on a single developer's machine
  # Enables team collaboration and state locking to prevent concurrent applies
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stterraformaiman001"
    container_name       = "tfstate"
    key                  = "azure-policy-demo.tfstate"
  }
}

# No credentials in code — pulled from environment variables at runtime
provider "azurerm" {
  features {}
}
