# CostCenter tag policy — calls the reusable azure_policy module
# Every resource must be tagged for cost attribution and chargeback
module "require_cost_center_tag" {
  source          = "./modules/azure_policy"
  subscription_id = var.subscription_id

  name         = "require-cost-center-tag"
  display_name = "Require CostCenter Tag on All Resources"
  description  = "Ensures all resources have a CostCenter tag for cost attribution."

  policy_rule = jsonencode({
    if = {
      # Triggers on any resource missing the CostCenter tag
      field  = "tags['CostCenter']"
      exists = false
    }
    then = {
      # Deny — untagged resources can't be tracked, so they shouldn't exist
      effect = "Deny"
    }
  })
}