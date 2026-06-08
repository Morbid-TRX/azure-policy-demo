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
}

# No credentials in code — pulled from environment variables at runtime
provider "azurerm" {
  features {}
}
