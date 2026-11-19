# AI usage disclosure

AI was used to implement and review this assignment. It did not approve or operate the deployment.

## Tools and roles

- **OpenAI Codex:** performed the first analysis of the assignment, implemented the Terraform, workflows and documentation in this repository, and made the commits.
- **Claude Code (Anthropic):** acted as an independent reviewer and planner. It reviewed the repository, wrote the step-by-step prompts given to Codex, and verified each step read-only using diffs, real Terraform plans against the personal subscription, Azure resource state and the GitHub API. It never applied, pushed or merged a change.
- **Human:** applied bootstrap, configured the GitHub environments and ruleset, pushed and merged every pull request, and approved every production run.

## Prompts that materially affected the result

| Paraphrased prompt | Why it worked |
|---|---|
| Harden bootstrap: isolate state by environment, constrain role assignment with ABAC, do not apply, and call out every destroy or replacement. | It stated security and lifecycle invariants, prohibited the risky action and required plan evidence. |
| Make a new environment one bootstrap map entry and one tfvars file. | It gave a concrete test for whether the environment design was reusable. |
| Make reviewers see impact in the PR and make production apply exactly the approved plan. | It described the delivery outcome rather than prescribing only workflow syntax. |
| Fix the required-check deadlock: state the docs-only and Dependabot failure modes and make the final gate fail closed. | It tied the implementation to observed failures and defined every accepted result. |

The repeated pattern was to state invariants and forbidden actions explicitly, require evidence such as a plan summary, request small commits, and prohibit push and apply.

## Where AI was wrong and how it was found

### Caught in review before anything was applied

| Mistake | How it was noticed | Fix |
|---|---|---|
| Development and production shared one state container, and all CI identities had blob write access on the storage account. A development identity or PR plan could overwrite production state. | The independent review compared identity scope with the state isolation claim. | Created per-environment containers and container-scoped roles. |
| `Role Based Access Control Administrator` was unconstrained; the first ABAC condition then compared full role resource IDs where Azure expects bare role GUIDs. | The bootstrap plan rendered the effective assignments and condition. | Limited assignable roles with ABAC and used the role-definition basename in the condition. |
| The documentation said a `CanNotDelete` lock would not block container deletion, although AzureRM 4.x manages those containers through ARM. | The reviewer checked Azure lock documentation and provider behavior. | Corrected the documentation and documented the required two-pass bootstrap change. |
| PR code could replace a production plan while it waited for approval. | The reviewer traced write access from the PR identity to `tfplans`. | Separated PR and main-plan identities and added SHA-256 verification before apply. |
| A plan identity with only `Reader` would fail to refresh an existing Container App because the provider calls `listSecrets`. | The AzureRM 4.81.0 provider source was inspected. | Added a custom plan-reader role and prohibited plain Container App secrets. |
| A `workflow_dispatch` `reason` input was interpolated directly into a shell script. | Workflow review followed untrusted inputs into `run:` blocks. | Passed the value through an environment variable and quoted it. |
| The proposed Key Vault name was already taken globally, and `Microsoft.App` was not registered although CI could not register providers. | A real plan and subscription state exposed both assumptions. | Added a state-stable random suffix and registered the provider in bootstrap. |
| Actions were pinned by mutable tags; TFLint with `--chdir` did not load the root config; unrelated project text appeared in documentation. | SHA checks, TFLint documentation and a documentation diff exposed the issues. | Pinned actions to full SHAs, added Dependabot, passed an absolute TFLint config path and removed the unrelated text. |
| The generated federated identity credential used a superseded schema (`resource_group_name` and `parent_id` instead of the AzureRM 4.x `user_assigned_identity_id`) and needed two commits to correct; the provider also lacked `storage_use_azuread` although shared keys were disabled on the state account. | Terraform validation and the first bootstrap run against the subscription. | The AzureRM 4.x schema (`04b61db`) and Azure AD data-plane access for storage (`e71294f`). |

### Caught only by CI or real Azure

| Mistake | How it was noticed | Fix |
|---|---|---|
| Key Vault lacked a default-deny network ACL (`AZU-0013`); state storage retained a public endpoint (`AZU-0012`). | Trivy blocked the first PR. | Fixed `AZU-0013`; accepted `AZU-0012` with an inline exception and the controls in [ADR-007](docs/DECISIONS.md#adr-007--state-storage-remains-reachable-through-its-public-endpoint). |
| Name-based federated subjects did not match GitHub's immutable OIDC subject on the new repository, causing `AADSTS700213`. | The first PR reached `azure/login` and Azure returned the actual mismatch. | Adopted immutable owner and repository IDs; see [ADR-008](docs/DECISIONS.md#adr-008--immutable-github-oidc-subjects). |
| Read-only plan identities could not create the first state blob because backend initialization takes a lease and writes empty state. | Terraform init returned 403 even though the containers existed. | Added narrow operator seed access and documented the one-time operation in [ADR-009](docs/DECISIONS.md#adr-009--state-seeding-and-operator-break-glass-access). |
| An empty plan output caused the sticky-comment job itself to fail. | A failed plan produced no comment body in CI. | Added a failure message with a workflow-run link. |
| Showing only the last 200 plan lines hid the Container Apps changes. | The PR comment was compared with the complete run log. | Post the full plan when it fits; otherwise put the resource summary first and link to the run. |

### Mistakes by the reviewing AI

| Mistake | How it was noticed | Fix |
|---|---|---|
| After state seeding, it reported the init problem as solved. That addressed only one cause: the backend also selected OIDC without a client ID. | The next PR init still failed and reported missing OIDC identity settings. | Set the appropriate `ARM_*` variables and `ARM_USE_OIDC` for every Terraform job. |
| It recommended moving production Container Apps to West Europe after a regional quota error, without preflight validation. The deployment then failed with `RequestDisallowedByAzure`. | `az deployment group validate` across regions showed the Free Trial allows only one managed environment globally, and West Europe rejected new customers. | Disabled the production runtime on this subscription and recorded the result in [ADR-010](docs/DECISIONS.md#adr-010--disable-the-production-container-apps-runtime-on-the-trial-subscription). The lesson is to preflight before recommending a location. |
| It assumed that the main ruleset existed. | The GitHub repository configuration was checked directly. | The human created and verified the ruleset. |
| It found that path-filtered required checks and skipped Dependabot plans permanently blocked docs-only and Dependabot PRs, but also caught an unverified Codex claim about Dependabot OIDC tokens. | The GitHub API and observed check runs established the deadlock; the OIDC claim had no supporting documentation. | Added the single fail-closed gate in [ADR-011](docs/DECISIONS.md#adr-011--single-required-ci-gate) and described skipping bot-authored Azure plans as a deliberate security decision. |

The generated output was usually plausible but was repeatedly wrong at platform edges such as identity, quotas and provider behavior. Real plans, CI, ARM preflight, provider source, product documentation and a second independent reviewer caught those errors; model confidence did not.

## Rolling out AI across a DevOps team

Start with one pilot team and approve a small set of tools on business accounts with contractual data controls. Put an `AGENTS.md` in every repository so the allowed commands, architecture invariants, validation requirements and forbidden operations are local and reviewable.

AI may draft code, documentation and reviews, explain plans, and propose tests. It must not hold cloud credentials, apply infrastructure, approve or merge a change, or read state and secrets. Customer data, credentials, secret values, state and plan binaries stay out of prompts. AI-generated work follows the same CI, plan review and human approval path as human-written work. The PR template must identify the tool, scope, validation and human reviewer.

Maintain a shared prompt library built around explicit invariants, forbidden actions and required evidence. Review useful and failed AI sessions together so the team learns where the tools are reliable and where they need independent verification. Measure lead time, change failure rate, review findings and rework, then revise the policy quarterly before expanding beyond the pilot.

## Data handling

No cloud credentials, secret values, customer data or proprietary source code were supplied to a model. The assignment text and repository content were used to derive this solution. Subscription IDs, principal IDs and resource names appear in human-readable plan output by design; that metadata trade-off is recorded in [ADR-006](docs/DECISIONS.md#adr-006--pull-request-plans-are-public-metadata). Binary plans and state remain outside GitHub and model prompts. The source PR review remains pending because the assignment document contained no usable PR URL.
