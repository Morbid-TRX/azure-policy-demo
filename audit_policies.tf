# AUDIT POLICY — not everything should be Deny
# Use Audit when you want visibility without blocking deployments
# Good for: new policies being rolled out, monitoring, reporting
# Rule of thumb: start with Audit, move to Deny once you understand the impact

# This policy audits VMs that don't have the Environment tag
# We audit instead of deny because Environment tagging is being phased in
# Once all teams are compliant, this can be changed to Deny
resource "azurerm_policy_definition" "audit_environment_tag" {
  name         = "audit-environment-tag"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Audit Missing Environment Tag on VMs"
  description  = "Audits VMs missing the Environment tag. Non-blocking — for visibility and reporting only."

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          # Only targets Virtual Machine resources
          field  = "type"
          equals = "Microsoft.Compute/virtualMachines"
        },
        {
          # Triggers if Environment tag is missing
          field  = "tags['Environment']"
          exists = false
        }
      ]
    }
    then = {
      # Audit — flags non-compliant resources without blocking them
      # Chosen over Deny because this policy is in rollout phase
      # Teams need time to add tags before enforcement begins
      effect = "Audit"
    }
  })
}

# POLICY ASSIGNMENT — audit only, subscription scope
resource "azurerm_subscription_policy_assignment" "audit_environment_tag_assignment" {
  name                 = "audit-environment-tag-assignment"
  display_name         = "Audit Missing Environment Tag"
  policy_definition_id = azurerm_policy_definition.audit_environment_tag.id
  subscription_id      = "/subscriptions/${var.subscription_id}"
}
