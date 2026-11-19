# Azure DevOps Tech Lead — Technical Assignment

Reference implementation for deploying a containerized API to Azure with Terraform and GitHub Actions.

## Deliverables

| Assignment deliverable | Location |
|---|---|
| Infrastructure | [`infrastructure/`](infrastructure/) and [architecture](docs/ARCHITECTURE.md) |
| CI/CD | [`.github/workflows/`](.github/workflows/) |
| Team setup (including AI assistant conventions) | [Day-one setup](docs/DAY_ONE.md) and [AI assistant conventions](AGENTS.md) |
| Work plan | [Work plan](docs/WORK_PLAN.md) |
| PR review | [PR review](docs/PR_REVIEW.md) |
| Client summary | [Client summary](docs/CTO_SUMMARY.md) |
| AI usage | [AI usage](AI_USAGE.md) |

## Decision summary

- **Compute:** Azure Container Apps in development. It gives a small team managed HTTPS ingress, revisions, autoscaling and low idle cost without the operational overhead of AKS. The current Free Trial allows only one managed environment globally, so production intentionally has no runtime until it moves to its target separate subscription.
- **Images:** Azure Container Registry (Basic SKU).
- **Secrets:** Azure Key Vault, accessed by managed identity. Secret values are never stored in Terraform state or GitHub.
- **Observability:** Log Analytics, with development application telemetry connected through its Container Apps environment. Production provisions the workspace and diagnostics but currently serves no traffic.
- **Delivery:** pull-request validation and plan, automatic development deployment after merge, and an approval-gated production deployment.
- **Authentication:** GitHub Actions OIDC to Azure. No client secret or long-lived Azure credential is required.

## Key decisions

- [ADR-001](docs/DECISIONS.md#adr-001--managed-serverless-containers): use managed serverless containers instead of operating AKS for the initial API.
- [ADR-002](docs/DECISIONS.md#adr-002--github-oidc): use short-lived GitHub OIDC identities rather than client secrets.
- [ADR-003](docs/DECISIONS.md#adr-003--one-module-isolated-states): share the module while isolating environment state, identity and lifecycle.
- [ADR-004](docs/DECISIONS.md#adr-004--secrets-by-reference): keep application secret values outside Terraform state.
- [ADR-005](docs/DECISIONS.md#adr-005--approved-plans-stay-in-azure-storage): store approved plans privately and verify their checksum before apply.
- [ADR-006](docs/DECISIONS.md#adr-006--pull-request-plans-are-public-metadata): accept identified metadata in public human-readable plans, but never publish binary plans.
- [ADR-007](docs/DECISIONS.md#adr-007--state-storage-remains-reachable-through-its-public-endpoint): retain the state public endpoint while using hosted runners and compensating controls.
- [ADR-008](docs/DECISIONS.md#adr-008--immutable-github-oidc-subjects): bind federation to immutable GitHub owner and repository IDs.
- [ADR-009](docs/DECISIONS.md#adr-009--state-seeding-and-operator-break-glass-access): seed new state through narrow operator access while plan identities remain read-only.
- [ADR-010](docs/DECISIONS.md#adr-010--disable-the-production-container-apps-runtime-on-the-trial-subscription): disable the production runtime until it has a subscription without the trial limit.
- [ADR-011](docs/DECISIONS.md#adr-011--single-required-ci-gate): expose one fail-closed required status for every pull request.

## Repository map

```text
.github/                 GitHub Actions, ownership and PR conventions
docs/                    architecture, onboarding, work plan and CTO summary
infrastructure/
  bootstrap/             one-time state and OIDC bootstrap
  modules/api-platform/  reusable application platform module
  platform/              shared environment root and per-environment tfvars
AGENTS.md                AI assistant safety and validation conventions
AI_USAGE.md              transparent AI usage log
```

## Delivery flow

1. A feature branch opens a pull request.
2. CI runs formatting, validation, lint/security checks and environment plans.
3. One sticky PR comment per environment is created or updated with its plan; binary plans are never uploaded as GitHub artifacts.
4. Merge to `main` plans and applies development, then creates the production plan.
5. The same run pauses at the protected GitHub `production` environment. After a required reviewer approves it, production verifies the saved plan checksum and applies that exact plan without recalculating it. On the current trial subscription this deploys production supporting resources only; the approval and checksum path remains fully exercised while `container_apps_enabled = false`.

## Beyond the brief, and why

- The platform was deployed to prove the OIDC, approval and plan-checksum paths end to end. Development serves the API; production exercises the full gated pipeline without a runtime because of the trial limit in [ADR-010](docs/DECISIONS.md#adr-010--disable-the-production-container-apps-runtime-on-the-trial-subscription).
- GitHub Actions are pinned to full commit SHAs, with Dependabot proposing controlled updates, to avoid trusting mutable tags.
- TFLint and Trivy add provider-aware linting and infrastructure security checks before a plan can pass the gate.
- One `required-checks` gate prevents docs-only and intentionally skipped jobs from leaving pull requests permanently pending.

This went well beyond the suggested 3–4 hours. The extra time went into the optional real deployment and fixing what it exposed.

## Local validation

```bash
terraform fmt -check -recursive infrastructure
terraform -chdir=infrastructure/platform init -backend=false
terraform -chdir=infrastructure/platform validate
```

No Azure resources are required for static validation. See [day-one setup](docs/DAY_ONE.md) before running a real plan.

## Important limitation

The assignment PDF references a pull request to review, but the provided copy contains no usable repository or PR URL. The review template is ready in [docs/PR_REVIEW.md](docs/PR_REVIEW.md); the actual review must be completed when the link is supplied.
