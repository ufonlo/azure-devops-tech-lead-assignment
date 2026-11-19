# AI assistant conventions

These rules apply to every AI coding assistant working in this repository.

## Repository map

- `infrastructure/bootstrap`: one-time state, identity and OIDC bootstrap.
- `infrastructure/platform`: shared platform root and environment tfvars.
- `infrastructure/modules/api-platform`: reusable Azure platform module.
- `.github/workflows`: pull-request validation and gated deployment.
- `docs`: architecture, ADRs, operations and delivery documentation.

## Required local checks

```bash
terraform fmt -check -recursive infrastructure
terraform -chdir=infrastructure/bootstrap init -backend=false
terraform -chdir=infrastructure/bootstrap validate
terraform -chdir=infrastructure/platform init -backend=false
terraform -chdir=infrastructure/platform validate
tflint --init --config "$PWD/.tflint.hcl"
tflint --recursive --config "$PWD/.tflint.hcl"
trivy config infrastructure
```

## Safety boundaries

- Never run `terraform apply`, `destroy`, `import` or any `terraform state` command. Never push or merge.
- Never edit bootstrap permissions or the GitHub ruleset/environment design unless the request explicitly requires it.
- Never read, print or paste credentials, secret values, Terraform state files or binary plan files.
- Preserve development/production isolation and do not expand permissions.
- Call out every proposed resource replacement or deletion explicitly before any human action.

## Workflow rules

- Pin every action to a full commit SHA.
- Do not place `${{ }}` expressions inside `run:` scripts; pass values through `env` and quote them in the shell.
- Set least-privilege permissions per job.
- Keep the `required-checks` gate fail-closed.

## Expected output

- Use small logical commits.
- Report the plan summary and list every destroy or replacement explicitly.
- When a decision changes, update its ADR and related documentation in the same pull request.
- Back claims about Azure or GitHub behavior with product documentation, provider source or a test such as ARM preflight. Label a claim `unverified` when none of those is available.
