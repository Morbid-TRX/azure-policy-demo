# POLICY DEFINITION — Allowed Locations
# Restricts resources to approved Azure regions only
# Cost angle: certain regions are cheaper than others
# Compliance angle: data residency requirements — data must stay in approved regions
# Without this, engineers can accidentally deploy to expensive or non-compliant regions
module "allowed_locations" {
  source          = "./modules/azure_policy"
  subscription_id = var.subscription_id

  name         = "allowed-locations"
  display_name = "Allowed Resource Locations"
  description  = "Restricts deployments to approved Azure regions for cost and compliance."

  policy_rule = jsonencode({
    if = {
      # Triggers on any resource being deployed outside approved regions
      allOf = [
        {
          field = "location"
          notIn = [
            "southeastasia", # Singapore — closest to Malaysia, lowest latency
            "eastasia",      # Hong Kong — secondary approved region
            "global"         # Required for global resources like Azure AD
          ]
        },
        {
          # Exclude resources that don't have a location (e.g. resource groups)
          field     = "location"
          notEquals = "global"
        }
      ]
    }
    then = {
      # Deny — deploying to unapproved regions could violate data residency laws
      # and incur unnecessary egress costs from cross-region traffic
      effect = "Deny"
    }
  })
}