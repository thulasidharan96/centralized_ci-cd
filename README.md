# platform-cicd (centralized_ci-cd)

Production-grade, organization-level GitHub Actions Internal Developer Platform (IDP) for reusable CI/CD across 10-100+ repositories.

## Folder Structure

```text
.github/
  actions/
    setup-runtime/action.yml
    generate-image-tags/action.yml
  workflows/
    build.yml
    test.yml
    security.yml
    docker.yml
    release.yml
    deploy.yml
scripts/
  deploy.sh
  rollback.sh
policies/
  org-security-baseline.md
  repository-ruleset.json
templates/
  consumer-repo/
    Dockerfile
    .github/workflows/ci.yml
    README.md
```

## Reusable Workflow Contracts (`workflow_call`)

All platform workflows are reusable and accept standardized inputs:

- `runtime`: `node|python|go`
- `environment`: `dev|test|prod` (deploy workflow)
- `image_name`: OCI image name (docker workflow)

Returned outputs include:

- `build.yml`: `artifact-name`, `build-sha`
- `test.yml`: `coverage-artifact`
- `security.yml`: `sbom-path`
- `docker.yml`: `image-uri`, `image-tag`, `image-digest`
- `release.yml`: `version`, `tag`
- `deploy.yml`: `deployed-environment`

## Pipeline Capabilities

- Build with dependency caching and matrix package support
- Lint + unit test + coverage reporting
- Security baseline: CodeQL + dependency/secrets scan (Trivy)
- SBOM generation via Syft (SPDX or CycloneDX)
- Container build + tagging (`latest`, `sha-*`, optional semver)
- Container vulnerability scanning (fail on HIGH/CRITICAL)
- Keyless image signing with Cosign + OIDC
- SLSA provenance attestations
- Multi-registry push support: GHCR, AWS ECR, Azure ACR
- Deployment workflow for AWS, Azure, and Vercel
- Rollback hook (`scripts/rollback.sh`) and deployment strategy flags (`rolling`, `blue-green`, `canary`)

## Environment Deployment Model

Use GitHub Environments:

- `dev`: auto from `develop`
- `test`: auto from `main`
- `prod`: only from tags `vX.Y.Z`

Set `prod` environment to require manual approvals before deployment.

## Required GitHub Secrets / Variables

Platform and consumer repositories should configure:

- `AWS_ACCOUNT_ID` as repository/org variable and pass to `docker.yml` input `aws-account-id` when using ECR
- OIDC IAM role ARN as variable (example: `vars.AWS_ROLE_TO_ASSUME`) and pass to `deploy.yml` input `aws-role-to-assume`
- Azure federated identity inputs:
  - `azure-client-id`
  - `azure-tenant-id`
  - `azure-subscription-id`
  - `registry_url` for ACR (e.g., `myregistry.azurecr.io`)
- `vercel_token` (as environment/repo secret when using Vercel)
- Optional app deploy vars (service names, healthcheck URLs)

## Required GitHub Organization/Repository Settings

- Branch protection or rulesets enabled (see `policies/repository-ruleset.json`)
- Require signed commits
- Require pull request approvals
- Require centralized checks (`build`, `lint`, `unit`, `codeql`, `dependency-and-secrets`)
- Restrict bypass permissions
- Enable GitHub Advanced Security where available

## Consumer Repository Usage

Copy:

- `templates/consumer-repo/.github/workflows/ci.yml`
- `templates/consumer-repo/Dockerfile`

The consumer workflow is intentionally <50 lines and contains no business logic, only calls to reusable workflows.
