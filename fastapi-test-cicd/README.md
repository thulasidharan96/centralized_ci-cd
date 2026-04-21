# fastapi-test-cicd

A reference FastAPI consumer repository that integrates with the [thulasidharan96/centralized_ci-cd](https://github.com/thulasidharan96/centralized_ci-cd) platform.

## Structure

```
fastapi-test-cicd/
├── .github/
│   └── workflows/
│       └── ci.yml          # Consumer workflow calling centralized reusable workflows
├── app/
│   ├── __init__.py
│   └── main.py             # FastAPI application
├── tests/
│   ├── conftest.py
│   └── test_main.py        # pytest tests
├── Dockerfile              # Multi-stage Python/FastAPI image
├── requirements.txt        # Python dependencies
└── README.md
```

## CI Pipeline

The `.github/workflows/ci.yml` calls reusable workflows pinned to `thulasidharan96/centralized_ci-cd@V1.0.0`:

| Stage    | Reusable Workflow          | Notes                                     |
|----------|---------------------------|-------------------------------------------|
| build    | `build.yml`               | Python 3.11, installs requirements.txt    |
| test     | `test.yml`                | `pytest -q` + coverage                   |
| security | `security.yml`            | CodeQL (python), Trivy, SBOM (spdx-json) |
| docker   | `docker.yml`              | Builds & pushes to GHCR on push/tag       |
| deploy   | `deploy.yml`              | AWS deploy; requires `AWS_ROLE_TO_ASSUME` |

### CI-only validation (no deploy)

Trigger via `workflow_dispatch` and set **skip_docker** and **skip_deploy** to `true`. Build, test, and security jobs will run; docker/deploy are skipped.

### Required secrets / vars for full CD

| Name                  | Type         | Used by    |
|-----------------------|--------------|------------|
| `AWS_ROLE_TO_ASSUME`  | repo var     | deploy job |
| `GITHUB_TOKEN`        | auto-provided| docker job |

## Local development

```bash
pip install -r requirements.txt
uvicorn app.main:app --reload        # http://localhost:8000
pytest -q                            # run tests
```
