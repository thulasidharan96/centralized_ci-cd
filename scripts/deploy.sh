#!/usr/bin/env bash
set -euo pipefail

cloud=""
environment=""
strategy="rolling"
service_name=""
image_uri=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cloud) cloud="$2"; shift 2 ;;
    --environment) environment="$2"; shift 2 ;;
    --strategy) strategy="$2"; shift 2 ;;
    --service-name) service_name="$2"; shift 2 ;;
    --image-uri) image_uri="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$cloud" || -z "$environment" ]]; then
  echo "cloud and environment are required" >&2
  exit 1
fi

echo "Starting ${cloud} deployment"
echo "Environment: ${environment}"
echo "Strategy: ${strategy}"
echo "Service: ${service_name:-n/a}"
echo "Image: ${image_uri:-n/a}"

case "$strategy" in
  rolling|blue-green|canary) ;;
  *) echo "Unsupported strategy: $strategy" >&2; exit 1 ;;
esac

case "$cloud" in
  aws)
    echo "Run aws ecs/eks deploy command here (OIDC-authenticated)"
    ;;
  azure)
    echo "Run az webapp/containerapp deploy command here (federated identity)"
    ;;
  *)
    echo "Unsupported cloud for this script: $cloud" >&2
    exit 1
    ;;
esac
