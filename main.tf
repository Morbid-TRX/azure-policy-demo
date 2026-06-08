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

# POLICY DEFINITION — the rulebook
# Cost-saving policy: blocks expensive VM sizes from being deployed
# Only allows B-series VMs which are the cheapest general-purpose SKUs in Azure
resource "azurerm_policy_definition" "allowed_vm_skus" {
  name         = "allowed-vm-skus"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Allowed Virtual Machine SKUs"
  description  = "Restricts VM deployments to approved cost-effective SKUs only."

  policy_rule = jsonencode({
    if = {
      # Both conditions must be true for the policy to trigger
      allOf = [
        {
          # Only targets Virtual Machine resources, nothing else
          field  = "type"
          equals = "Microsoft.Compute/virtualMachines"
        },
        {
          # If the VM size is NOT in this approved list, trigger the effect
          # B-series are low-cost burstable VMs — suitable for dev/test workloads
          field = "Microsoft.Compute/virtualMachines/sku.name"
          notIn = ["Standard_B1s", "Standard_B1ms", "Standard_B2s"]
        }
      ]
    }
    then = {
      # Deny — hard block, the deployment will fail immediately
      # Chosen over Audit because cost control needs enforcement, not just visibility
      effect = "Deny"
    }
  })
}

# POLICY ASSIGNMENT — deploying the rulebook to our subscription
# Scope set at subscription level — enforces across all resource groups
# This is where the policy actually becomes active
resource "azurerm_subscription_policy_assignment" "allowed_vm_skus_assignment" {
  name                 = "allowed-vm-skus-assignment"
  display_name         = "Enforce Allowed VM SKUs"
  policy_definition_id = azurerm_policy_definition.allowed_vm_skus.id

  # Subscription scope — applies to everything in this account
  subscription_id = "/subscriptions/${var.subscription_id}"
}

# POLICY DEFINITION — Require CostCenter tag
# Every resource must have a CostCenter tag for cost tracking and chargeback
# Without this, finance can't attribute cloud spend to the right team
resource "azurerm_policy_definition" "require_cost_center_tag" {
  name         = "require-cost-center-tag"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Require CostCenter Tag on All Resources"
  description  = "Ensures all resources have a CostCenter tag for cost attribution."

  policy_rule = jsonencode({
    if = {
      # Triggers on any resource that is missing the CostCenter tag
      field  = "tags['CostCenter']"
      exists = false
    }
    then = {
      # Deny — block the resource from being created without the tag
      # Audit would allow untagged resources to exist, defeating the purpose
      effect = "Deny"
    }
  })
}

# POLICY ASSIGNMENT — enforce tag requirement across the subscription
resource "azurerm_subscription_policy_assignment" "require_cost_center_tag_assignment" {
  name                 = "require-cost-center-tag-assignment"
  display_name         = "Enforce CostCenter Tag"
  policy_definition_id = azurerm_policy_definition.require_cost_center_tag.id

  # Same subscription scope — applies to all resource groups
  subscription_id = "/subscriptions/${var.subscription_id}"
}