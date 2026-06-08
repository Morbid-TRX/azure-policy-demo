# Expose the policy definition ID so initiatives can reference it
output "policy_definition_id" {
  description = "The ID of the created policy definition"
  value       = azurerm_policy_definition.this.id
}

# Expose the policy assignment ID for use in exemptions
output "policy_assignment_id" {
  description = "The ID of the created policy assignment"
  value       = azurerm_subscription_policy_assignment.this.id
}