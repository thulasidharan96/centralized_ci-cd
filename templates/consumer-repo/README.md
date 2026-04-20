# Consumer Repository Template

This template intentionally keeps `.github/workflows/ci.yml` thin (<50 lines) and delegates all CI/CD logic to reusable platform workflows.

It now also supports manual `workflow_dispatch` runs with optional stage skip flags:

- `skip_build`
- `skip_test`
- `skip_security`
- `skip_docker`
- `skip_deploy`
