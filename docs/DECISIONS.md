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

## ADR-006 — Pull-request plans are public metadata

**Decision:** when the repository becomes public, keep human-readable Terraform
plans in PR comments and Actions logs, but never publish binary plan files.

**Reason:** in-context plans make infrastructure review practical. Terraform masks
sensitive values, but subscription IDs, principal IDs and resource names can still
be visible. This metadata exposure is accepted for the assignment; secrets must
remain in Key Vault and no sensitive values may be passed as ordinary Terraform
inputs or Container App secrets.

## ADR-007 — State storage remains reachable through its public endpoint

**Decision:** accept `AZU-0012` for the Terraform state storage account while CI
runs on GitHub-hosted runners. The runners use dynamic public IP addresses, so a
default-deny storage firewall would make the backend unreliable. The exception is
declared inline on the resource rather than in a global Trivy ignore file.

**Compensating controls:** shared-key access is disabled, authentication is Entra
ID only, anonymous blob access is disabled, TLS 1.2 is required, RBAC is scoped to
individual containers, and state is protected by versioning, seven-day soft delete
and a `CanNotDelete` resource lock.

**Production path:** move execution to self-hosted runners inside an Azure VNet and
use a storage private endpoint, or use GitHub-hosted runners with GitHub's Azure
private networking, before disabling public network access and changing the
storage firewall default action to deny.

## ADR-008 — Immutable GitHub OIDC subjects

**Decision:** federated credentials use GitHub's immutable subject format,
`repo:owner@owner_id/repository@repository_id:<context>`, for pull requests, the
`main` branch and deployment environments. The human-readable owner/name remains
an independent bootstrap input for repository configuration and documentation.

**Reason:** numeric owner and repository IDs survive repository renames and prevent
a deleted repository name from being re-created and trusted by the existing Azure
federation. This repository was created after GitHub enabled immutable OIDC
subjects by default, so name-based Azure subjects do not match its tokens.

**Trade-off:** bootstrap requires two additional public identifiers. They can be
read through `gh api` or GitHub's unauthenticated public repository REST endpoint
and are safe to store in the non-secret Terraform configuration.

