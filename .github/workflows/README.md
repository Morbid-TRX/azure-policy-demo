# Azure Cost Governance — Policy as Code

End-to-end Azure cost-saving policies implemented using Terraform and enforced via GitHub Actions CI/CD.

Built as part of an Azure Cloud Engineer assessment to demonstrate policy-driven cloud governance at scale.

---

## Policies Implemented

### 1. Allowed VM SKUs
Blocks deployment of expensive VM sizes. Only cost-effective B-series VMs are permitted.
- **Effect:** Deny
- **Scope:** Subscription

### 2. Require CostCenter Tag
Every resource must have a `CostCenter` tag before it can be deployed.
- **Effect:** Deny  
- **Scope:** Subscription

---

## Initiative
Both policies are bundled into a **Cost Governance Initiative** for simplified assignment and auditing at scale.

---

## Project Structure
azure-policy-demo/
├── main.tf          # Policy definitions, assignments, and initiative
├── variables.tf     # Input variables — no hardcoded values
├── .gitignore       # Excludes Terraform state and sensitive files
├── .github/
├── workflows/
└── secret-scan.yml  # Gitleaks secret scanning on every push

---

## Security Practices
- No credentials or IDs hardcoded in code
- All sensitive values passed via environment variables at runtime
- Gitleaks secret scanning runs on every push and pull request
- Branch protection enforced — all changes to main require a pull request

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
| Deny over Audit | Cost control needs enforcement, not just visibility |
| Subscription scope | Enforces governance across all resource groups |
| Initiative over individual assignments | Easier to manage and audit at scale |
| Environment variables for auth | Credentials never touch the codebase |