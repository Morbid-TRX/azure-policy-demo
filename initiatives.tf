# POLICY INITIATIVE — bundles all policies into a single assignable unit
# At enterprise scale, one initiative assignment replaces dozens of individual ones
# Easier to audit, easier to manage, easier to enforce consistently
resource "azurerm_policy_set_definition" "cost_governance_initiative" {
  name         = "cost-governance-initiative"
  policy_type  = "Custom"
  display_name = "Cost Governance Initiative"
  description  = "Bundles all cost-saving and security policies into a single assignable initiative."

  # Reference module outputs instead of direct resources
  # This is why we exposed policy_definition_id as a module output
  policy_definition_reference {
    policy_definition_id = module.allowed_vm_skus.policy_definition_id
    reference_id         = "allowed-vm-skus"
    parameter_values     = jsonencode({})
  }

  policy_definition_reference {
    policy_definition_id = module.require_cost_center_tag.policy_definition_id
    reference_id         = "require-cost-center-tag"
    parameter_values     = jsonencode({})
  }

  policy_definition_reference {
    policy_definition_id = module.no_public_ip_on_vms.policy_definition_id
    reference_id         = "no-public-ip-on-vms"
    parameter_values     = jsonencode({})
  }

  policy_definition_reference {
    policy_definition_id = module.allowed_locations.policy_definition_id
    reference_id         = "allowed-locations"
    parameter_values     = jsonencode({})
  }
}

# INITIATIVE ASSIGNMENT — one assignment covers all policies
resource "azurerm_subscription_policy_assignment" "cost_governance_assignment" {
  name                 = "cost-governance-assignment"
  display_name         = "Enforce Cost Governance Initiative"
  policy_definition_id = azurerm_policy_set_definition.cost_governance_initiative.id
  subscription_id      = "/subscriptions/${var.subscription_id}"
}
