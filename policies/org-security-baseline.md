# Organization Security Baseline

- Enforce branch protection/rulesets on default branches.
- Require signed commits.
- Require pull requests with at least one approval.
- Require status checks from centralized CI/CD reusable workflows.
- Restrict who can bypass branch protection.
- Use GitHub Environments with required reviewers for `prod`.
- Use OIDC federation for cloud credentials (AWS/Azure) and Sigstore keyless signing.
- Block long-lived static cloud keys and rotate any existing credentials.
