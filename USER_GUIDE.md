# CI/CD Platform User Guide

This guide explains how to use the centralized GitHub Actions CI/CD platform in this repository across the full software delivery lifecycle.

## 1) What this platform provides

Reusable workflows for:

1. Build (`build.yml`)
2. Test + Lint + Coverage (`test.yml`)
3. Security scans + SBOM (`security.yml`)
4. Container build/sign/provenance (`docker.yml`)
5. Release/versioning (`release.yml`)
6. Deployment (`deploy.yml`)

All workflows are `workflow_call` workflows for organization-wide reuse.

---

## 2) Platform workflow contracts

### Common inputs

- `runtime`: `node | python | go`
- `runtime-version`: runtime version (for example `20`, `3.12`, `1.23`)
- `matrix-packages`: JSON array for monorepo paths (for example `[".","services/api"]`)

### Common output pattern

Workflows emit outputs that chain to downstream jobs:

- Build output -> test/security/docker
- Docker output (`image-uri`, `image-digest`) -> deploy
- Release output (`version`, `tag`) -> production controls

---

## 3) Stage-by-stage usage

### Stage 1: BUILD (`.github/workflows/build.yml`)

### Purpose

- Install dependencies
- Compile/build application
- Cache dependencies
- Upload build artifacts

### Key inputs

- `runtime`
- `runtime-version`
- `cache-dependency-path`
- `build-command` (optional override)
- `matrix-packages`

### Output

- `artifact-name`
- `build-sha`

### Notes

- If `build-command` is omitted, runtime-specific defaults are used.
- For monorepos, pass `matrix-packages` JSON.

---

### Stage 2 + 3: TEST + LINT (`.github/workflows/test.yml`)

### Purpose

- Run lint checks
- Run unit tests
- Publish coverage artifacts

### Key inputs

- `lint-command`, `test-command`, `coverage-command` (optional overrides)
- `runtime`, `runtime-version`, `matrix-packages`

### Output

- `coverage-artifact`

### Notes

- Lint and test jobs run in parallel.
- Coverage artifacts are uploaded with commit SHA naming.

---

### Stage 4 + 5: SECURITY + SBOM (`.github/workflows/security.yml`)

### Purpose

- Run CodeQL (SAST)
- Run dependency scanning (Trivy vuln scanner)
- Run secret detection (Trivy secret scanner)
- Run optional DAST (OWASP ZAP baseline) when a target URL is provided
- Generate SBOM via Syft (`SPDX` or `CycloneDX`)

### Key inputs

- `runtime`
- `sbom-format`: `spdx-json` or `cyclonedx-json`
- `upload-sbom`
- `dast-target-url` (optional, enables DAST job when set)

### Output

- `sbom-path`

### Notes

- Dependency and secret scans fail on HIGH/CRITICAL findings.
- DAST is executed only when `dast-target-url` is provided by the caller.
- SARIF is uploaded for security visibility in GitHub Security tab.

---

### Stage 6 + 7 + 8 + 9 + 10: CONTAINER + SCAN + SIGN + PROVENANCE + ARTIFACT STORAGE (`.github/workflows/docker.yml`)

### Purpose

- Build and push container images
- Apply deterministic tagging (`latest`, `sha-*`, optional semver)
- Scan container image for vulnerabilities
- Sign image with keyless Cosign + OIDC
- Generate and push SLSA provenance attestation
- Push artifacts to GHCR/ECR/ACR

### Key inputs

- `image_name` (required)
- `registry`: `ghcr | ecr | acr`
- `registry-url` (required for ACR)
- `aws-account-id`, `aws-region`, `aws-role-to-assume` (for ECR)
- `azure-client-id`, `azure-tenant-id`, `azure-subscription-id` (for ACR)
- `semver` (optional, e.g. `v1.2.3`)
- `provenance`

### Outputs

- `image-uri`
- `image-tag`
- `image-digest`

### Notes

- Keyless signing uses GitHub OIDC token, no static signing keys.
- Container scan fails on HIGH/CRITICAL severities.

---

### Stage 11: RELEASE/VERSIONING (`.github/workflows/release.yml`)

### Purpose

- Resolve semantic version (`vX.Y.Z`)
- Create GitHub release with notes

### Key inputs

- `version` (optional explicit semver)
- `target-branch`
- `generate-notes`

### Outputs

- `version`
- `tag`

### Notes

- Uses semver guardrails.
- If no version is passed, next patch version is derived from valid existing tags.

---

### Stage 12: DEPLOYMENT (`.github/workflows/deploy.yml`)

### Purpose

Environment-based deployment with approval gates and rollback hooks.

### Supported clouds

- AWS (OIDC)
- Azure (Federated identity)
- Vercel (token)

### Key inputs

- `environment`: `dev | test | prod`
- `cloud`: `aws | azure | vercel`
- `image_uri`
- `strategy`: `rolling | blue-green | canary`
- `healthcheck_url`
- `rollback_on_failure`

### Deployment behavior model

- `develop` -> deploy `dev`
- `main` -> deploy `test`
- `vX.Y.Z` tag -> deploy `prod`

### Notes

- `prod` must be protected by GitHub Environment required reviewers.
- Rollback script executes on failure when enabled.

---

## 4) Consumer repository setup

Use the template:

- `templates/consumer-repo/.github/workflows/ci.yml`
- `templates/consumer-repo/Dockerfile`

Template workflow is intentionally thin and contains no business logic.

For manual runs, the template also exposes optional `workflow_dispatch` booleans to bypass specific stages:

- `skip_build`
- `skip_test`
- `skip_security`
- `skip_docker`
- `skip_deploy`

---

## 5) Required GitHub permissions/secrets/settings

## Permissions baseline

```yaml
permissions:
  contents: read
  id-token: write
```

Additional scoped permissions are applied where needed (`packages`, `security-events`, `deployments`, `attestations`).

## Secrets / variables

- `AWS_ACCOUNT_ID` (variable, for ECR endpoint composition)
- `AWS_ROLE_TO_ASSUME` (variable, consumed by deploy)
- Azure OIDC inputs (`azure-client-id`, `azure-tenant-id`, `azure-subscription-id`)
- `vercel_token` (secret for Vercel deployments)

## Governance

- Branch protection/rulesets
- Require signed commits
- Required checks from centralized workflows
- GitHub Environments with required approvals for `prod`

See:

- `policies/repository-ruleset.json`
- `policies/org-security-baseline.md`

---

## 6) Example end-to-end flow

1. Developer pushes to `develop`
2. Consumer workflow calls reusable build/test/security workflows
3. Docker workflow builds/scans/signs image and publishes to registry
4. Deploy workflow deploys to `dev`
5. Merge to `main` triggers `test` environment deployment
6. Create tag `vX.Y.Z` to trigger `prod` deployment (with approvals)

---

## 7) Troubleshooting

- **Workflow call permission errors**: ensure caller repo grants required permissions and `id-token: write`.
- **OIDC auth fails (AWS/Azure)**: verify trust policy/federated credential subject conditions.
- **Container push fails**: verify registry selection inputs and auth settings.
- **Security scan failures**: review Trivy/CodeQL outputs and fix HIGH/CRITICAL findings.
- **Prod blocked**: expected if environment reviewers have not approved.

---

## 8) Operational recommendations

- Pin reusable workflow references in consumer repos to a release tag or commit SHA.
- Promote platform changes via semantic releases.
- Keep cloud identity trust policies least-privileged.
- Keep deployment scripts idempotent and observable.
