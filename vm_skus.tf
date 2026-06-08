# VM SKU policy — calls the reusable azure_policy module
# Only allows cost-effective B-series VMs to be deployed
module "allowed_vm_skus" {
  source          = "./modules/azure_policy"
  subscription_id = var.subscription_id

  name         = "allowed-vm-skus"
  display_name = "Allowed Virtual Machine SKUs"
  description  = "Restricts VM deployments to approved cost-effective SKUs only."

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          # Only targets Virtual Machine resources
          field  = "type"
          equals = "Microsoft.Compute/virtualMachines"
        },
        {
          # Block any VM size not in the approved low-cost list
          # B-series are burstable, cheapest general-purpose SKUs in Azure
          field = "Microsoft.Compute/virtualMachines/sku.name"
          notIn = ["Standard_B1s", "Standard_B1ms", "Standard_B2s"]
        }
      ]
    }
    then = {
      # Deny over Audit — cost control needs enforcement not just visibility
      effect = "Deny"
    }
  })
}