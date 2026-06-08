# Root outputs — shows what was deployed after terraform apply
# Useful for debugging and confirming deployments in CI/CD logs

output "allowed_vm_skus_policy_id" {
  description = "The ID of the Allowed VM SKUs policy definition"
  value       = module.allowed_vm_skus.policy_definition_id
}

output "require_cost_center_tag_policy_id" {
  description = "The ID of the Require CostCenter Tag policy definition"
  value       = module.require_cost_center_tag.policy_definition_id
}

output "no_public_ip_policy_id" {
  description = "The ID of the No Public IP policy definition"
  value       = module.no_public_ip_on_vms.policy_definition_id
}

output "cost_governance_initiative_id" {
  description = "The ID of the Cost Governance Initiative"
  value       = azurerm_policy_set_definition.cost_governance_initiative.id
}