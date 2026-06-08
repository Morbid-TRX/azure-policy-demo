# Subscription ID passed in as a variable — never hardcoded in main.tf
# Value is set via environment variable TF_VAR_subscription_id at runtime
variable "subscription_id" {
  description = "The Azure subscription ID to assign policies to"
  type        = string

  # Validates the format is a proper UUID — catches typos early
  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.subscription_id))
    error_message = "Subscription ID must be a valid UUID format."
  }
}