# POLICY EXEMPTION — intentionally bypass a policy for a specific resource
# Use case: a legacy VM that can't be retagged immediately needs a time-limited exemption
# Exemptions are auditable — they show up in Azure Policy compliance reports
# Never use exemptions to permanently bypass governance — always set an expiry

resource "azurerm_resource_group_policy_exemption" "legacy_vm_exemption" {
  name                 = "legacy-vm-cost-center-exemption"
  resource_group_id    = "/subscriptions/${var.subscription_id}/resourceGroups/rg-terraform-state"
  policy_assignment_id = module.require_cost_center_tag.policy_assignment_id

  # Waiver — used when the policy doesn't apply to this specific case
  # Mitigated — used when compensating controls exist elsewhere
  exemption_category = "Waiver"

  display_name = "Legacy VM CostCenter Tag Exemption"
  description  = "Temporary exemption for legacy VM pending tag remediation. Expires 2026-09-01."

  # Always set an expiry — exemptions should never be permanent
  expires_on = "2026-09-01T00:00:00Z"
}