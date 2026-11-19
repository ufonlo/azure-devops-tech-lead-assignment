# Remaining production-readiness work

Estimates are rough engineering time and exclude external approval or Azure provisioning delays.

## First-week shared checkpoints

- **Day 1:** confirm ownership, sequencing and the target production subscription.
- **Day 3:** review the image-promotion design, network design and recovery test plan together.
- **Day 5:** demonstrate completed controls, update risks and agree the next-week scope.

## Engineer A — platform and security

| Priority | Estimate | Task | Acceptance criterion |
|---|---:|---|---|
| P0 | 1 day | Create or select a separate production subscription, reproduce bootstrap/platform prerequisites there, and enable `container_apps_enabled` as described in ADR-010. | A reviewed production plan targets the production subscription, contains the Container Apps runtime, and contains no unintended deletion or replacement of existing resources. |
| P0 | 2–3 days | Design private connectivity for state, ACR and Key Vault; decide whether self-hosted runners are required under ADR-007. | Approved network diagram and Terraform plan show private access paths, DNS resolution and a documented runner path without weakening current identity controls. |
| P0 | 1 day | Replace the standing state-operator assignment with a PIM-eligible Entra group under ADR-009. | Eligible membership, activation duration and audit path are documented; normal CI retains no state write access. |
| P1 | 0.5 day | Move bootstrap state to a dedicated remote backend. | Bootstrap state lives in a separate locked storage account with versioning and restricted data access, and no copy remains on a workstation. |
| P1 | 1–2 days | Add service alerts, an operational dashboard and subscription budgets. | Alerts cover availability and failed deployment signals, a dashboard shows agreed service indicators, and budget notifications reach named owners. |
| P1 | 1–2 days | Write state and Key Vault recovery procedures and test a restore. | A runbook identifies owners, prerequisites and rollback steps; a non-production restore is completed and evidence is recorded. |
| P1 | 1–2 days | Add automated tests for the platform module. | Tests cover required inputs, production image pinning, runtime-disabled behavior and representative resource assertions, and run in CI. |

## Engineer B — delivery and application

| Priority | Estimate | Task | Acceptance criterion |
|---|---:|---|---|
| P0 | 2 days | Build and test the application image, scan it, push it to ACR and record its immutable digest. | CI fails on a build, test or agreed scan threshold; a successful run publishes one digest-addressable image without deploying a mutable tag to production. |
| P0 | 1–2 days | Promote the tested development digest to production. | The production plan consumes the exact digest exercised in development, and the approved saved plan remains checksum-verified before apply. |
| P0 | 1–2 days | Add a post-deploy smoke test and revision rollback. | The pipeline verifies the agreed health endpoint after deployment and can return traffic to the previous healthy revision when the test fails. |
| P1 | 1 day | Schedule read-only drift detection. | A scheduled job runs a non-applying plan with the plan identity, reports drift to maintainers and cannot mutate state. |
| P1 | 1 day | Add delivery tests around reusable workflows and failure paths. | Tests or controlled runs cover failed image scan, stale plan rejection, failed smoke test and rollback reporting. |

## Team controls when the second engineer joins

| Priority | Estimate | Task | Acceptance criterion |
|---|---:|---|---|
| P0 | 0.5 day | Enable one required PR approval, required CODEOWNERS review and no production self-review. | The ruleset and production environment require another engineer; each engineer can approve the other's change without creating a deadlock. |
