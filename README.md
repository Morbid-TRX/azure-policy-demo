# Azure Cost Governance — Policy as Code

End-to-end Azure cost-saving and security policies implemented using reusable Terraform modules, enforced via GitHub Actions CI/CD, with remote state management and full branch protection.

Built as part of an Azure Cloud Engineer assessment to demonstrate policy-driven cloud governance at scale.

---

## What This Does

This project deploys a set of Azure Policies that enforce cost and security guardrails across an Azure subscription. Every policy is defined as code, version controlled in Git, and deployed via Terraform — meaning every change is tracked, reviewed, and auditable.

---

## Policies Implemented

### 1. Allowed VM SKUs — `vm_skus.tf`
Blocks deployment of expensive VM sizes. Only cost-effective B-series VMs are permitted.
- **Effect:** Deny
- **Scope:** Subscription
- **Why Deny over Audit:** Audit still allows the VM to be created and start billing. By the time someone reviews the flag, the cost is already incurred. Deny stops it before it exists — no VM, no bill.
- **Why B-series:** Cheapest general-purpose SKUs in Azure. Suitable for dev/test workloads. If a team needs a larger size, it goes through a change request — not a unilateral deployment.

### 2. Require CostCenter Tag — `cost_tags.tf`
Every resource must have a `CostCenter` tag before it can be deployed.
- **Effect:** Deny
- **Scope:** Subscription
- **Why Deny over Audit:** An untagged resource that exists defeats the purpose of the policy. If teams can create resources without tags, they will — especially under pressure. Deny makes compliance the path of least resistance.
- **Why tags matter:** Without tags, finance gets one giant bill with no way to attribute spend to teams or projects. Tags enable chargeback reporting and cost visibility per team, per project, per environment.

### 3. No Public IP on Virtual Machines — `no_public_ip.tf`
Prevents VMs from being deployed with a public IP address.
- **Effect:** Deny
- **Scope:** Subscription
- **Why Deny over Audit:** A public IP that gets flagged after creation is already a security risk. The VM is already internet-exposed. Block it before it exists.
- **Security angle:** Removes direct internet exposure. All traffic must route through a controlled entry point — load balancer, VPN gateway, or Azure Bastion.
- **Cost angle:** Public IPs in Azure have an hourly charge even when idle. Eliminating them reduces cost.

### 4. Audit Missing Environment Tag — `audit_policies.tf`
Audits VMs missing the `Environment` tag. Non-blocking — for visibility only.
- **Effect:** Audit
- **Scope:** Subscription
- **Why Audit and not Deny:** This tag requirement is being phased in. Teams need time to comply before hard enforcement begins. Audit gives visibility into who is non-compliant without blocking their work. Once compliance reaches an acceptable level, the effect is changed to Deny. This is the standard responsible rollout pattern — Audit first, Deny later.

### 5. Allowed Resource Locations — `allowed_locations.tf`
Restricts deployments to approved Azure regions only.
- **Effect:** Deny
- **Scope:** Subscription
- **Why Deny over Audit:** Deploying to unapproved regions could violate data residency laws and incur cross-region egress costs immediately. Block it before it exists.
- **Cost angle:** Certain regions are cheaper than others. Restricting to Southeast Asia and East Asia keeps latency low and costs predictable.
- **Compliance angle:** Data residency requirements — regulated data must stay within approved regions.

---

## Policy Exemptions — `exemptions.tf`

Not every resource can comply with every policy immediately. Exemptions allow intentional, auditable bypasses for specific resources.

The example here exempts a specific resource group from the CostCenter tag policy — simulating a legacy environment being onboarded.

**Key principles:**
- Exemptions are always scoped to the smallest possible resource — never subscription-wide
- Every exemption has an expiry date — exemptions should never be permanent
- `Waiver` category — used when the policy genuinely doesn't apply to this case
- `Mitigated` category — used when compensating controls exist elsewhere

---

## Initiative — `initiatives.tf`

All Deny policies are bundled into a **Cost Governance Initiative**.

**Why initiatives matter at scale:**

| Scenario | Without Initiative | With Initiative |
|---|---|---|
| 3 policies, 1 subscription | 3 assignments | 1 assignment |
| 3 policies, 5 subscriptions | 15 assignments | 5 assignments |
| 10 policies, 10 subscriptions | 100 assignments | 10 assignments |

One initiative assignment covers all policies in the bundle. Adding a new policy to the initiative automatically enforces it everywhere the initiative is assigned — no need to create new assignments per subscription.

---

## Module Architecture — `modules/azure_policy/`

Every policy calls the same reusable `azure_policy` module instead of repeating the same Terraform structure.

**Why this matters:**
- Adding a new policy = one new `.tf` file, call the module, done
- No copy-paste errors — the definition and assignment logic lives in one place
- Changes to how policies are deployed only need to be made once in the module
- Scales to 50 policies as easily as 3

**What the module does:**
- Creates the policy definition
- Creates the subscription-level assignment
- Exposes `policy_definition_id` and `policy_assignment_id` as outputs for use in initiatives and exemptions
- Uses `depends_on` to ensure assignment never runs before definition exists

---

## Scaling Scenarios

**What if we have 5 subscriptions (dev, test, staging, UAT, prod)?**

Assign the initiative at **Management Group level** instead of subscription level. One assignment covers all subscriptions automatically. For environment-specific rules — assign a stricter policy to prod only, a relaxed version to dev only.

**What if we want different rules per environment?**

Same policy definition, different assignments. Prod gets Deny. Dev gets Audit. Same rulebook, different enforcement per scope.

**What if a team needs an exception?**

Create a scoped exemption with an expiry date. Never modify the policy itself — that would affect everyone. The exemption is auditable and temporary.

**What if we need to add a new policy?**

Create a new `.tf` file in the root, call the `azure_policy` module, add it to the initiative. Three steps, no changes to existing files.

**What if the subscription ID changes?**

Update the `TF_VAR_subscription_id` environment variable. Nothing in the code changes — that's why it's a variable, not hardcoded.

**What if data residency requirements change?**

Update the `notIn` list in `allowed_locations.tf` with the new approved regions. One file change, one PR, automatically enforced everywhere the initiative is assigned.

---

## Project Structure
```bash
azure-policy-demo/
├── main.tf                    # Provider block and remote backend config
├── variables.tf               # Root input variables with validation
├── outputs.tf                 # Exposes all policy and initiative IDs
├── initiatives.tf             # Cost Governance Initiative + assignment
├── vm_skus.tf                 # Allowed VM SKUs policy
├── cost_tags.tf               # Require CostCenter Tag policy
├── no_public_ip.tf            # No Public IP on VMs policy
├── audit_policies.tf          # Audit Missing Environment Tag policy
├── allowed_locations.tf       # Allowed Resource Locations policy
├── exemptions.tf              # Example policy exemption with expiry
├── modules/
│   └── azure_policy/
│       ├── main.tf            # Reusable policy definition + assignment
│       ├── variables.tf       # Module input variables
│       └── outputs.tf         # Exposes policy_definition_id and policy_assignment_id
└── .github/
    └── workflows/
        ├── secret-scan.yml    # Gitleaks secret scanning on every push and PR
        └── terraform-plan.yml # Terraform plan on every PR with PR comment output
```

---

## CI/CD Pipeline

Every pull request to main automatically runs:

1. **Secret scan** — Gitleaks scans entire commit history for credentials
2. **Terraform format check** — fails if any file needs formatting
3. **Terraform init** — connects to remote state backend
4. **Terraform plan** — reads live Azure state, shows what will change
5. **PR comment** — posts the plan output so reviewers see the impact before merging

Nothing merges to main without all checks passing.

---

## Remote State

State is stored in Azure Blob Storage instead of locally.

| | Local State | Remote State |
|---|---|---|
| Team collaboration | ❌ One machine | ✅ Shared |
| State locking | ❌ No locking | ✅ Azure handles it |
| Disaster recovery | ❌ Machine dies, state gone | ✅ Persisted in Azure |
| CI/CD compatible | ❌ | ✅ |

---

## Security Practices

- No credentials or IDs hardcoded in code
- All sensitive values passed via environment variables at runtime
- Service Principal used for CI/CD authentication — not personal credentials
- Gitleaks secret scanning on every push and pull request
- Branch protection — all changes require a pull request
- Terraform fmt enforced in CI — consistent code style across the team
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
| Deny over Audit for cost policies | Cost control needs enforcement not visibility — Audit lets the bill run |
| Audit for Environment tag | Phased rollout — visibility before enforcement |
| Allowed locations policy | Prevents costly and non-compliant region deployments |
| Module architecture | Reusable, scalable — add policies without duplication |
| Initiative over individual assignments | One assignment per environment instead of one per policy per environment |
| Subscription scope for Deny policies | Enforces across all resource groups — no gaps |
| Management Group scope for enterprise | One assignment covers all subscriptions — scales to any org size |
| Exemptions with expiry | Intentional bypasses must be auditable and temporary |
| Remote state in Azure Blob | Team collaboration, state locking, disaster recovery |
| Environment variables for auth | Credentials never touch the codebase |
| Service Principal for CI/CD | Dedicated robot account — not personal credentials |
| Branch protection + secret scanning | No unreviewed or credential-leaking code reaches main |
| Terraform fmt in CI | Consistent code style enforced automatically |