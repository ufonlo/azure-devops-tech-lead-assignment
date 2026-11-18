# Architecture decision records

## ADR-001 — Managed serverless containers

**Decision:** use Azure Container Apps for the initial API platform.

**Reason:** fastest safe path for a small containerized service, native revisions and autoscaling, and materially less toil than AKS.

**Trade-off:** less control and fewer Kubernetes extension points. Revisit when Kubernetes-specific requirements are demonstrated.

## ADR-002 — GitHub OIDC

**Decision:** federate GitHub Actions to Azure managed identities.

**Reason:** short-lived tokens eliminate stored Azure client secrets and can be scoped to PR, branch and environment subjects.

## ADR-003 — One module, isolated states

**Decision:** compose dev and prod from one versioned module while keeping separate roots and state keys.

**Reason:** consistency without coupling lifecycle or permissions.

## ADR-004 — Secrets by reference

**Decision:** Terraform creates the vault and access model but does not create application secret values.

**Reason:** secret values otherwise enter Terraform state. Applications reference externally populated Key Vault secrets through managed identity.

