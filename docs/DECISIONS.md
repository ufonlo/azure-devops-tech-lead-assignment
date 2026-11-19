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

## ADR-009 — State seeding and operator break-glass access

**Decision:** PR and main-plan identities remain read-only on environment state.
After bootstrap creates a new state container, an explicitly configured state
operator runs `terraform init` once to create its first state blob. Operators have
`Storage Blob Data Contributor` only on `tfstate-<environment>` containers and no
access through this assignment to the `tfplans` container.

**Reason:** Terraform 1.9 initializes an absent AzureRM state blob by taking a
lease and writing empty state. Granting plan identities write access merely to
support that one-time operation would weaken the separation between planning and
deployment.

**Break-glass use:** the same narrowly scoped role permits an operator to recover
a stale lease or restore a protected blob version. Every use should be deliberate,
audited and removed when no longer required. In production this would be assigned
to a PIM-eligible Entra group rather than retained as a standing user role.

## ADR-010 — Run the production Container Apps environment in West Europe

**Decision:** while this project uses the Free Trial subscription, place only the
production Container Apps managed environment in West Europe. Keep the production
resource group, managed identity, ACR, purge-protected Key Vault and Log Analytics
workspace in North Europe. The Container App follows its managed environment.

**Reason:** the subscription permits one Container Apps managed environment per
region, and development already consumes the North Europe quota. The first
production deployment consequently failed with
`MaxNumberOfRegionalEnvironmentsInSubExceeded`. Moving all production resources
would create unnecessary replacements and cannot safely replace the purge-protected
vault.

**Trade-offs:** images are pulled across regions from ACR, telemetry is ingested
across regions into Log Analytics, calls to North Europe dependencies gain a small
amount of latency, and cross-region data transfer may add a small charge.

**Production path:** use separate Azure subscriptions for development and
production, or request a managed-environment quota increase. After either change,
remove `container_apps_location` from `prod.tfvars` so Container Apps uses the
normal environment location again.

