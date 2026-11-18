# Azure DevOps Tech Lead — Technical Assignment

Reference implementation for deploying a containerized API to Azure with Terraform and GitHub Actions.

## Decision summary

- **Compute:** Azure Container Apps. It gives a small team managed HTTPS ingress, revisions, autoscaling and low idle cost without the operational overhead of AKS.
- **Images:** Azure Container Registry (Basic SKU).
- **Secrets:** Azure Key Vault, accessed by managed identity. Secret values are never stored in Terraform state or GitHub.
- **Observability:** Log Analytics through the Container Apps environment.
- **Delivery:** pull-request validation and plan, automatic development deployment after merge, and an approval-gated production deployment.
- **Authentication:** GitHub Actions OIDC to Azure. No client secret or long-lived Azure credential is required.

## Repository map

```text
.github/                 GitHub Actions, ownership and PR conventions
docs/                    architecture, onboarding, work plan and CTO summary
infrastructure/
  bootstrap/             one-time state and OIDC bootstrap
  modules/api-platform/  reusable application platform module
  platform/              shared environment root and per-environment tfvars
AI_USAGE.md              transparent AI usage log
```

## Delivery flow

1. A feature branch opens a pull request.
2. CI runs formatting, validation, lint/security checks and environment plans.
3. Plan summaries are attached to the workflow summary for review before merge;
   binary plans are never uploaded as GitHub artifacts.
4. Merge to `main` deploys development.
5. Production is a separate workflow_dispatch deployment protected by the GitHub
   `production` environment and required reviewers. It applies the immutable plan
   previously written to private Azure Storage by the main-branch plan identity.

## Local validation

```bash
terraform fmt -check -recursive infrastructure
terraform -chdir=infrastructure/platform init -backend=false
terraform -chdir=infrastructure/platform validate
```

No Azure resources are required for static validation. See [day-one setup](docs/DAY_ONE.md) before running a real plan.

## Important limitation

The assignment PDF references a pull request to review, but the provided copy contains no usable repository or PR URL. The review template is ready in [docs/PR_REVIEW.md](docs/PR_REVIEW.md); the actual review must be completed when the link is supplied.

