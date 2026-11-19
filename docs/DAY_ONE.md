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

Copy `infrastructure/bootstrap/terraform.tfvars.example` to `terraform.tfvars`,
then replace the subscription ID, `OWNER/REPOSITORY`, immutable owner ID and
immutable repository ID. Add the signed-in operator object ID to
`state_operator_object_ids`; this grants break-glass access only to the
environment state containers, not to `tfplans`:

```bash
AZURE_CONFIG_DIR="$HOME/.azure-personal" az ad signed-in-user show \
  --query id -o tsv
```

Read both public GitHub IDs with either:

```bash
gh api repos/OWNER/REPOSITORY --jq '.owner.id, .id'
```

or request the public REST endpoint
`https://api.github.com/repos/OWNER/REPOSITORY` and read `owner.id` and the
top-level `id`. Keep `github_repository` in owner/name form; bootstrap combines
it with the numeric IDs for immutable OIDC subjects. Then run:

```bash
terraform -chdir=infrastructure/bootstrap init
terraform -chdir=infrastructure/bootstrap plan -out=bootstrap.tfplan
terraform -chdir=infrastructure/bootstrap apply bootstrap.tfplan
terraform -chdir=infrastructure/bootstrap output
```

Bootstrap is intentionally a separate, one-time administrative step. Store its state securely; after GitHub OIDC is active, normal delivery has no long-lived credentials.

### Seed each remote state once

An empty backend container has no state blob. Terraform 1.9 creates and leases an
empty state during the first `init`, which deliberately cannot be done by the
read-only PR and main-plan identities. After applying bootstrap, use the signed-in
state operator once to seed every environment. Obtain the backend names from
`terraform -chdir=infrastructure/bootstrap output`, then run:

```bash
export AZURE_CONFIG_DIR="$HOME/.azure-personal"
az login --tenant <PERSONAL_TENANT_ID>

export TF_STATE_RESOURCE_GROUP="<backend.resource_group_name>"
export TF_STATE_STORAGE_ACCOUNT="<backend.storage_account_name>"

for environment in dev prod; do
  terraform -chdir=infrastructure/platform init \
    -reconfigure \
    -input=false \
    -backend-config="resource_group_name=${TF_STATE_RESOURCE_GROUP}" \
    -backend-config="storage_account_name=${TF_STATE_STORAGE_ACCOUNT}" \
    -backend-config="container_name=tfstate-${environment}" \
    -backend-config="key=api-platform/${environment}.tfstate" \
    -backend-config="use_azuread_auth=true"
done
```

This is a one-time operation for each newly created environment. Do not run an
apply while seeding state.

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

Protect `main`: require pull requests, resolved conversations and exactly one
status check named `required-checks` with source **GitHub Actions**. Require
branches to be up to date before merging. A single gate ensures every pull
request receives a stable required check even when path-based work is skipped or
a reusable workflow caller is intentionally skipped. Use the approval settings
described above. The reusable comment job is the only job granted
`pull-requests: write`; do not enable the repository setting that allows GitHub
Actions to create and approve pull requests.

## 4. First change

1. Create a feature branch.
2. Change one low-risk tag or module input.
3. Open a PR and inspect both sticky, read-only (`-lock=false`) plan comments
   plus the fmt, validate, TFLint and Trivy checks. Fork PRs run static checks but
   cannot pass the gate when Terraform or workflows change because GitHub does
   not issue their jobs a trusted Azure OIDC token; a maintainer must reproduce
   such a change on a branch in this repository.
   Dependabot PRs skip Azure plans because their runs receive a read-only
   `GITHUB_TOKEN`, so the sticky plan comment cannot be posted, and this project
   deliberately does not give bot-authored dependency updates Azure credentials:
   a compromised dependency or action could use them. `required-checks` accepts
   that exception. The updated actions are first exercised by the main run on
   development before the approval-gated production run. A maintainer who wants
   plans on the PR can push a commit to the Dependabot branch.
4. Merge only after the plan is understood.
5. Confirm main plans and applies development, then plans production.
6. Approve the `production` environment and verify that the exact plan stored
   in `tfplans` is downloaded, checksum-verified and applied without re-planning.

To add another environment, add `envs/<name>.tfvars`, add the environment to
the bootstrap `environments` map, create its GitHub Environment with an
`AZURE_CLIENT_ID` variable, then add one reusable-workflow call to both the PR
and main workflows. Add the new plan job to the `required-checks` job's `needs`
list and result checks. No new workflow file is required.

## 5. Team conventions for humans and AI

Repository safety boundaries, workflow conventions and required checks are
defined in [`AGENTS.md`](../AGENTS.md). Human and AI contributors follow the
same validation and review process; disclose material AI assistance in the pull
request.

