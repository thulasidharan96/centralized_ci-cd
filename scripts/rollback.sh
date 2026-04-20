#!/usr/bin/env bash
set -euo pipefail

cloud=""
environment=""
service_name=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cloud) cloud="$2"; shift 2 ;;
    --environment) environment="$2"; shift 2 ;;
    --service-name) service_name="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

echo "Rollback initiated for ${cloud}/${environment} service=${service_name:-n/a}"
case "$cloud" in
  aws)
    echo "Run aws rollback to last known healthy task definition"
    ;;
  azure)
    echo "Run az rollback to last known healthy revision"
    ;;
  vercel)
    echo "Run vercel rollback to previous deployment alias"
    ;;
  *)
    echo "Unsupported cloud: $cloud" >&2
    exit 1
    ;;
esac
