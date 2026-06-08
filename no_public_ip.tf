# No public IP policy — calls the reusable azure_policy module
# Reduces attack surface and eliminates unnecessary public IP costs
module "no_public_ip_on_vms" {
  source          = "./modules/azure_policy"
  subscription_id = var.subscription_id

  name         = "no-public-ip-on-vms"
  display_name = "No Public IP on Virtual Machines"
  description  = "Prevents VMs from being deployed with a public IP address."

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Network/networkInterfaces"
        },
        {
          field     = "Microsoft.Network/networkInterfaces/ipConfigurations[*].publicIpAddress"
          notEquals = ""
        }
      ]
    }
    then = {
      effect = "Deny"
    }
  })
}