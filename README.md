# Azure Cost Governance — Policy as Code

End-to-end Azure cost-saving and security policies implemented using Terraform modules, enforced via GitHub Actions CI/CD, and deployed to a real Azure subscription.

Built as part of an Azure Cloud Engineer assessment to demonstrate policy-driven cloud governance at scale.

---

## Policies Implemented

### 1. Allowed VM SKUs
Blocks deployment of expensive VM sizes. Only cost-effective B-series VMs are permitted.
- **Effect:** Deny
- **Scope:** Subscription
- **Why Deny over Audit:** Cost control needs enforcement, not just visibility. Audit still allows the VM to be created and start billing.

### 2. Require CostCenter Tag
Every resource must have a `CostCenter` tag before it can be deployed. Enables cost attribution and chargeback reporting.
- **Effect:** Deny
- **Scope:** Subscription
- **Why Deny over Audit:** Untagged resources can't be tracked. Allowing them to exist defeats the purpose of the policy.

### 3. No Public IP on Virtual Machines
Prevents VMs from being deployed with a public IP address. Reduces attack surface and eliminates unnecessary public IP costs.
- **Effect:** Deny
- **Scope:** Subscription
- **Why Deny over Audit:** Security and cost enforcement — a public IP that gets flagged after creation is already a risk.

---

## Initiative
All three policies are bundled into a **Cost Governance Initiative** for simplified assignment and auditing at scale. One initiative assignment replaces managing three separate policy assignments per environment.

---

## Project Structure
```
azure-policy-demo/
├── main.tf                    # Provider block only
├── variables.tf               # Root variables
├── initiatives.tf             # Initiative definition and assignment
├── vm_skus.tf                 # Calls azure_policy module for VM SKU policy
├── cost_tags.tf               # Calls azure_policy module for tag policy
├── no_public_ip.tf            # Calls azure_policy module for public IP policy
├── modules/
│   └── azure_policy/
│       ├── main.tf            # Reusable policy definition + assignment
│       ├── variables.tf       # Module input variables
│       └── outputs.tf         # Exposes policy_definition_id for initiative use
└── .github/
└── workflows/
└── secret-scan.yml    # Gitleaks secret scanning on every push
```

---

## Module Design
The `azure_policy` module is a reusable template — define the policy structure once, pass in different values per policy. Adding a new policy means creating one new `.tf` file in the root and calling the module. No duplication, no copy-paste errors.

---

## Security Practices
- No credentials or IDs hardcoded in code
- All sensitive values passed via environment variables at runtime
- Gitleaks secret scanning runs on every push and pull request
- Branch protection enforced — all changes to main require a pull request
- `.gitignore` covers all Terraform state files including numbered backups

---

## Deployment

### Prerequisites
- Terraform installed
- Azure CLI installed and authenticated via `az login`

### Set environment variables
```bash
$env:ARM_TENANT_ID="your-tenant-id"
$env:ARM_SUBSCRIPTION_ID="your-subscription-id"
$env:TF_VAR_subscription_id="your-subscription-id"
```

### Deploy
```bash
terraform init
terraform plan
terraform apply
```

---

## Design Decisions

| Decision | Reasoning |
|---|---|
| Deny over Audit | Cost and security controls need enforcement, not just visibility |
| Subscription scope | Enforces governance across all resource groups |
| Module architecture | Reusable, scalable — add new policies without duplication |
| Initiative over individual assignments | Easier to manage and audit at scale |
| Environment variables for auth | Credentials never touch the codebase |
| Branch protection + secret scanning | No unreviewed or credential-leaking code reaches main |