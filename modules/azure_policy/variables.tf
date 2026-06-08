# Module inputs — each policy passes its own values here
variable "name" {
  description = "Unique name for the policy definition"
  type        = string
}

variable "display_name" {
  description = "Human-readable name shown in Azure portal"
  type        = string
}

variable "description" {
  description = "What this policy does and why"
  type        = string
}

variable "policy_rule" {
  description = "The policy rule logic in JSON format"
  type        = string
}

variable "subscription_id" {
  description = "The Azure subscription ID to assign the policy to"
  type        = string
}