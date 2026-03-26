#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
. "$SCRIPT_DIR/canisterworm-common.sh"

# Flags repos that reference Trivy tooling in CI/infra files. Adjust or
# remove this check if Trivy usage is not relevant to your investigation.
TRIVY_REGEX='aquasecurity/trivy-action|aquasecurity/setup-trivy|get\.trivy\.dev|ghcr\.io/aquasecurity/trivy|public\.ecr\.aws/aquasecurity/trivy|aquasec/trivy|(^|[[:space:]])trivy([[:space:]]|$)'

if [ "$#" -gt 0 ]; then
  ROOTS=("$@")
else
  ROOTS=(".")
fi

init_findings

scan_repo_files() {
  local check_name="$1"
  local regex="$2"
  local tmp matches=0
  tmp="$(mktemp)"

  find "${ROOTS[@]}" \
    \( -path '*/node_modules/*' -o -path '*/.git/*' \) -prune -o \
    -type f \( -name 'package.json' -o -name 'package-lock.json' -o -name 'pnpm-lock.yaml' -o -name 'yarn.lock' -o -name 'npm-shrinkwrap.json' \) \
    -exec grep -HniE "$regex" {} + >"$tmp" 2>/dev/null

  if [ -s "$tmp" ]; then
    matches=1
    record_grep_output "$check_name" <"$tmp"
  fi

  rm -f "$tmp"
  return "$matches"
}

scan_trivy_refs() {
  local tmp matches=0
  tmp="$(mktemp)"

  find "${ROOTS[@]}" \
    \( -path '*/node_modules/*' -o -path '*/.git/*' \) -prune -o \
    -type f \( -name '*.yml' -o -name '*.yaml' -o -name 'Dockerfile' -o -name 'Dockerfile.*' -o -name '*.sh' -o -name '*.md' \) \
    ! -name 'scan-repos.sh' ! -name 'scan-macos.sh' ! -name 'scan-linux.sh' \
    -exec grep -HniE "$TRIVY_REGEX" {} + >"$tmp" 2>/dev/null

  if [ -s "$tmp" ]; then
    matches=1
    record_grep_output "trivy_reference" <"$tmp"
  fi

  rm -f "$tmp"
  return "$matches"
}

found=0

scan_repo_files "malicious_package_reference" "$PACKAGE_REGEX" || found=1
scan_trivy_refs || found=1

print_results "$found"
