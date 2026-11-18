# Architecture decision records

## ADR-001 — Managed serverless containers

**Decision:** use Azure Container Apps for the initial API platform.

**Reason:** fastest safe path for a small containerized service, native revisions and autoscaling, and materially less toil than AKS.

**Trade-off:** less control and fewer Kubernetes extension points. Revisit when Kubernetes-specific requirements are demonstrated.

## ADR-002 — GitHub OIDC

**Decision:** federate GitHub Actions to Azure managed identities.

**Reason:** short-lived tokens eliminate stored Azure client secrets and can be scoped to PR, branch and environment subjects.

## ADR-003 — One module, isolated states

**Decision:** compose environments from one shared root and versioned module,
while keeping separate tfvars, state containers, identities and GitHub environments.

**Reason:** consistency without coupling lifecycle or permissions.

## ADR-005 — Approved plans stay in Azure Storage

**Decision:** upload main-branch saved plans to a private `tfplans` container,
expire current and historical versions after seven days, and let each deployer
read but not write them.

**Reason:** apply verifies the plan checksum and uses exactly the planned file
without exposing potentially sensitive plan values as GitHub artifacts.

## ADR-004 — Secrets by reference

**Decision:** Terraform creates the vault and access model but does not create application secret values.

**Reason:** secret values otherwise enter Terraform state. Applications reference externally populated Key Vault secrets through managed identity.

