# Day-one setup

## 1. Prerequisites

- A personal Microsoft account with an Azure subscription; do not use an employer subscription.
- A private GitHub repository.
- Terraform 1.7+, Azure CLI and permission to create resource groups, identities and role assignments.

## 2. Bootstrap Azure once

Keep the personal Azure account isolated from other Azure CLI sessions. Set a
dedicated Azure CLI profile directory before every `az` or Terraform command.
Authenticate to the tenant used by the subscription recorded in
`terraform.tfvars`; Terraform uses that explicit subscription value and never
relies on the Azure CLI default subscription:

```bash
export AZURE_CONFIG_DIR="$HOME/.azure-personal"
az login --tenant <PERSONAL_TENANT_ID>
az account show --subscription <PERSONAL_SUBSCRIPTION_ID> \
  --query '{name:name,id:id,tenantId:tenantId,user:user.name}'
```

Copy `infrastructure/bootstrap/terraform.tfvars.example` to `terraform.tfvars`, replace the subscription ID and `OWNER/REPOSITORY`, then run:

```bash
terraform -chdir=infrastructure/bootstrap init
terraform -chdir=infrastructure/bootstrap plan -out=bootstrap.tfplan
terraform -chdir=infrastructure/bootstrap apply bootstrap.tfplan
terraform -chdir=infrastructure/bootstrap output
```

Bootstrap is intentionally a separate, one-time administrative step. Store its state securely; after GitHub OIDC is active, normal delivery has no long-lived credentials.

## 3. Configure GitHub

Create environments named exactly `development` and `production`. Add at least one required reviewer to production.

Set repository variables from bootstrap output:

| Variable | Source |
|---|---|
| `AZURE_TENANT_ID` | `github_oidc.tenant_id` |
| `AZURE_SUBSCRIPTION_ID` | `github_oidc.subscription_id` |
| `AZURE_PR_CLIENT_ID` | `github_oidc.pr_client_id` |
| `AZURE_PLAN_CLIENT_ID` | `github_oidc.plan_client_id` |
| `AZURE_DEV_CLIENT_ID` | `github_oidc.dev_client_id` |
| `AZURE_PROD_CLIENT_ID` | `github_oidc.prod_client_id` |
| `TF_STATE_RESOURCE_GROUP` | `backend.resource_group_name` |
| `TF_STATE_STORAGE_ACCOUNT` | `backend.storage_account_name` |

State container names are fixed by environment: `tfstate-dev` and
`tfstate-prod`. Approved production plans are stored in the private `tfplans`
container and expire after seven days.

These are identifiers, not credentials. No GitHub secret is required for Azure login.

Protect `main`: require pull requests, one approval, resolved conversations, CODEOWNERS review and the Terraform checks.

## 4. First change

1. Create a feature branch.
2. Change one low-risk tag or module input.
3. Open a PR and inspect both read-only (`-lock=false`) plans and the Trivy result.
4. Merge only after the plan is understood.
5. Confirm development deploys automatically.
6. Run the production workflow manually and verify approval is requested before
   the exact plan stored in `tfplans` is downloaded and applied.

## 5. Team conventions for humans and AI

- Never paste credentials, secret values, state files or client data into prompts or source control.
- AI may draft code and explanations; an engineer owns every line merged.
- Ask for small diffs and state explicit invariants: no resource deletion, no permission expansion, no environment coupling.
- Run deterministic tools after AI edits: format, validate, security scan and plan.
- Record meaningful AI use in the PR and update `AI_USAGE.md` for assignment-level work.

