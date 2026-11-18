# AI usage disclosure

AI assistance was used as an accelerator, not as an authority.

## Tools and scope

- **OpenAI Codex:** decomposed the assignment, drafted architecture alternatives, produced the initial repository skeleton and Terraform/GitHub Actions implementation, and suggested validation commands.

## Representative prompts

- Analyse the supplied technical assignment before implementation.
- Design a low-cost Azure platform for a containerized API with dev/prod, Terraform, GitHub Actions OIDC, visible pull-request plans and production approval.
- Implement the design in a new private GitHub repository with a reviewable commit history.

## Human validation required

- Architecture choices are reviewed against the stated workload rather than copied blindly.
- Terraform is formatted and statically validated locally.
- Workflow permissions and OIDC subject claims must be checked against the final GitHub owner/repository.
- A real Azure plan must be reviewed before any apply.
- Generated statements are not treated as evidence of deployed infrastructure.

## Data handling

No cloud credentials, secret values, customer data or proprietary source code were supplied to the model. The assignment text was used only to derive this solution. The source PR review is intentionally pending because no PR URL was present in the provided document.

