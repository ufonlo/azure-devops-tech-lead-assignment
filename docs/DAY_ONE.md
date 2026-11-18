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

Create environments named exactly `development` and `production`:

- `development`: restrict deployments to the `main` branch, use no required
  reviewer, and set environment variable
  `AZURE_CLIENT_ID` from `github_oidc.dev_client_id`.
- `production`: add the appropriate required reviewer, configure self-review for
  the team size, restrict deployments to the `main` branch and set environment variable
  `AZURE_CLIENT_ID` from `github_oidc.prod_client_id`.

### Single-maintainer setup used in this repository

The repository owner is the required production reviewer, environment self-review
is allowed, and the `main` ruleset requires zero PR approvals. This avoids a
deadlock while retaining an explicit production gate. When a second engineer
joins, enable one required PR approval, require CODEOWNERS review, disable
production self-review and make the other engineer a required production reviewer.

Do not create repository-level dev or prod client ID variables. The apply jobs
read the same `AZURE_CLIENT_ID` name from their selected GitHub Environment.

Set repository variables from bootstrap output:

| Variable | Source |
|---|---|
| `AZURE_TENANT_ID` | `github_oidc.tenant_id` |
| `AZURE_SUBSCRIPTION_ID` | `github_oidc.subscription_id` |
| `AZURE_PR_CLIENT_ID` | `github_oidc.pr_client_id` |
| `AZURE_PLAN_CLIENT_ID` | `github_oidc.plan_client_id` |
| `TF_STATE_RESOURCE_GROUP` | `backend.resource_group_name` |
| `TF_STATE_STORAGE_ACCOUNT` | `backend.storage_account_name` |

State container names are derived as `tfstate-<environment>` and state keys as
`api-platform/<environment>.tfstate`. Plans for main deployments are stored in
the private `tfplans` container, checksum-verified before apply and removed by
the seven-day lifecycle rule. Plan binaries are never uploaded as GitHub
artifacts.

These are identifiers, not credentials. No GitHub secret is required for Azure login.

Protect `main`: require pull requests, resolved conversations and the Terraform
checks. Use the approval settings described above. The reusable comment job is
the only job granted `pull-requests: write`; do not enable the repository setting
that allows GitHub Actions to create and approve pull requests.

## 4. First change

1. Create a feature branch.
2. Change one low-risk tag or module input.
3. Open a PR and inspect both sticky, read-only (`-lock=false`) plan comments
   plus the fmt, validate, TFLint and Trivy checks. Fork PRs run only static
   checks because GitHub does not issue their jobs a trusted Azure OIDC token.
   Dependabot PRs also skip Azure plans because their workflow token is read-only.
4. Merge only after the plan is understood.
5. Confirm main plans and applies development, then plans production.
6. Approve the `production` environment and verify that the exact plan stored
   in `tfplans` is downloaded, checksum-verified and applied without re-planning.

To add another environment, add `envs/<name>.tfvars`, add the environment to
the bootstrap `environments` map, create its GitHub Environment with an
`AZURE_CLIENT_ID` variable, then add one reusable-workflow call to both the PR
and main workflows. No new workflow file is required.

## 5. Team conventions for humans and AI

- Never paste credentials, secret values, state files or client data into prompts or source control.
- AI may draft code and explanations; an engineer owns every line merged.
- Ask for small diffs and state explicit invariants: no resource deletion, no permission expansion, no environment coupling.
- Run deterministic tools after AI edits: format, validate, security scan and plan.
- Record meaningful AI use in the PR and update `AI_USAGE.md` for assignment-level work.

