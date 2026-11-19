# Azure DevOps Tech Lead — Technical Assignment

Reference implementation for deploying a containerized API to Azure with Terraform and GitHub Actions.

## Decision summary

- **Compute:** Azure Container Apps in development. It gives a small team managed HTTPS ingress, revisions, autoscaling and low idle cost without the operational overhead of AKS. The current Free Trial allows only one managed environment globally, so production intentionally has no runtime until it moves to its target separate subscription.
- **Images:** Azure Container Registry (Basic SKU).
- **Secrets:** Azure Key Vault, accessed by managed identity. Secret values are never stored in Terraform state or GitHub.
- **Observability:** Log Analytics, with development application telemetry connected through its Container Apps environment. Production provisions the workspace and diagnostics but currently serves no traffic.
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
3. One sticky PR comment per environment is created or updated with its plan;
   binary plans are never uploaded as GitHub artifacts.
4. Merge to `main` plans and applies development, then creates the production plan.
5. The same run pauses at the protected GitHub `production` environment. After a
   required reviewer approves it, production verifies the saved plan checksum and
   applies that exact plan without recalculating it. On the current trial subscription
   this deploys production supporting resources only; the approval and checksum path
   remains fully exercised while `container_apps_enabled = false`.

## Local validation

```bash
terraform fmt -check -recursive infrastructure
terraform -chdir=infrastructure/platform init -backend=false
terraform -chdir=infrastructure/platform validate
```

No Azure resources are required for static validation. See [day-one setup](docs/DAY_ONE.md) before running a real plan.

## Important limitation

The assignment PDF references a pull request to review, but the provided copy contains no usable repository or PR URL. The review template is ready in [docs/PR_REVIEW.md](docs/PR_REVIEW.md); the actual review must be completed when the link is supplied.

