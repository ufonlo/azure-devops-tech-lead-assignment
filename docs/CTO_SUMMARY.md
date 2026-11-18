# CTO summary

This proposal moves the API to Azure using a deliberately small managed platform: Azure Container Apps, Container Registry, Key Vault and Log Analytics. Terraform defines one reusable platform module, while development and production retain separate state, identities and lifecycle. This provides consistency without allowing a development change or credential to silently cross into production.

GitHub Actions uses Azure workload identity federation, so the company stores no long-lived cloud credential in GitHub. Every infrastructure pull request is formatted, validated and security-scanned, and produces separate development and production plans for review before merge. Development deploys automatically from the protected main branch. Production is explicit and requires a human approval through a protected GitHub environment.

Container Apps is preferred over AKS for the first stage because the current requirement is a containerized API, not a Kubernetes platform. It gives managed ingress, revisions, autoscaling and scale-to-zero while reducing cost and operational burden for a small team. The design preserves a migration path to AKS if Kubernetes-specific needs emerge.

The main residual risks are bootstrap privilege, public endpoints, untested application health behavior and incomplete disaster-recovery requirements. The next increments are immutable image promotion, smoke tests, alerting, private networking where justified, and a rollback game day. AI may accelerate drafting, but deterministic validation, human plan review and explicit data-handling rules remain mandatory.

