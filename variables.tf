# Subscription ID passed in as a variable — never hardcoded in main.tf
# Value is set via environment variable TF_VAR_subscription_id at runtime
variable "subscription_id" {
  description = "The Azure subscription ID to assign policies to"
  type        = string
}