# Two-engineer delivery plan

## Engineer A — platform and security

1. Run and document bootstrap in the personal Azure subscription.
2. Verify OIDC subjects and least-privilege role assignments.
3. Validate dev/prod state isolation and Key Vault access by managed identity.
4. Add alerts, dashboards and an operational runbook.

## Engineer B — delivery and application integration

1. Add the API build/test workflow and immutable image tagging.
2. Push images to ACR and pass the digest into Terraform.
3. Define health endpoints, smoke tests and rollback checks.
4. Exercise the PR, development and production promotion flows.

## Shared checkpoints

- Architecture and threat-model review before first apply.
- Pair review of the first plan and first production promotion.
- A short game day: failed health check, bad revision rollback and expired/incorrect permission.
- Definition of done: documentation, deterministic checks, rollback evidence and no secrets in repository/state.

