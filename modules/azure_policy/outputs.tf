# Expose the policy definition ID so initiatives can reference it
output "policy_definition_id" {
  description = "The ID of the created policy definition"
  value       = azurerm_policy_definition.this.id
}