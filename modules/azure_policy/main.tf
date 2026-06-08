# Reusable policy module — define once, use for every policy
# Pass in different values each time instead of repeating the same structure

# POLICY DEFINITION — built from module inputs
resource "azurerm_policy_definition" "this" {
  name         = var.name
  policy_type  = "Custom"
  mode         = "All"
  display_name = var.display_name
  description  = var.description
  policy_rule  = var.policy_rule
}

# POLICY ASSIGNMENT — automatically created for every policy using this module
# Scope at subscription level — can be overridden per policy if needed
resource "azurerm_subscription_policy_assignment" "this" {
  name                 = "${var.name}-assignment"
  display_name         = "Enforce ${var.display_name}"
  policy_definition_id = azurerm_policy_definition.this.id
  subscription_id      = "/subscriptions/${var.subscription_id}"

  # Explicit dependency — assignment must wait for definition to exist
  depends_on = [azurerm_policy_definition.this]
}