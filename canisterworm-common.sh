#!/usr/bin/env bash

set -u

PACKAGE_REGEX='@leafnoise/mirage|jest-preset-ppf|babel-plugin-react-pure-component|eslint-config-service-users|opengov-k6-core|cit-playwright-tests|react-leaflet-marker-layer|react-leaflet-cluster-layer|eslint-config-ppf|@opengov/form-renderer|@opengov/qa-record-types-api|@airtm/uuid-base32|@opengov/form-builder|@emilgroup/document-uploader|@emilgroup/task-sdk-node|@emilgroup/discount-sdk|@emilgroup/accounting-sdk|@emilgroup/docxtemplater-util|@emilgroup/discount-sdk-node|@emilgroup/gdv-sdk-node|@emilgroup/setting-sdk|@emilgroup/changelog-sdk-node|@emilgroup/partner-portal-sdk|@emilgroup/process-manager-sdk|@emilgroup/numbergenerator-sdk-node|@emilgroup/task-sdk|@emilgroup/customer-sdk|@emilgroup/commission-sdk-node|@emilgroup/partner-sdk|@emilgroup/commission-sdk|@teale\.io/eslint-config|@emilgroup/document-sdk-node|@emilgroup/partner-sdk-node|@emilgroup/billing-sdk|@emilgroup/insurance-sdk|@emilgroup/auth-sdk|@emilgroup/payment-sdk|@emilgroup/customer-sdk-node|@emilgroup/accounting-sdk-node|@emilgroup/tenant-sdk|@emilgroup/notification-sdk-node|@emilgroup/tenant-sdk-node|@emilgroup/document-sdk|@emilgroup/payment-sdk-node|@emilgroup/public-api-sdk|@emilgroup/auth-sdk-node|@emilgroup/account-sdk-node|@emilgroup/process-manager-sdk-node|@emilgroup/public-api-sdk-node|@emilgroup/partner-portal-sdk-node|@emilgroup/translation-sdk-node|@emilgroup/gdv-sdk|@emilgroup/account-sdk|@emilgroup/claim-sdk-node|@emilgroup/api-documentation|@emilgroup/billing-sdk-node|@emilgroup/insurance-sdk-node|react-autolink-text|@opengov/ppf-backend-types|react-leaflet-heatmap-layer|@opengov/form-utils|@opengov/ppf-eslint-config|@pypestream/floating-ui-dom'
PROCESS_REGEX='pgmon|pglog|service\.py'
LOG_REGEX="$PACKAGE_REGEX|pgmon|pglog|postinstall"

init_findings() {
  FINDINGS_FILE="$(mktemp)"
  export FINDINGS_FILE
  trap 'rm -f "$FINDINGS_FILE"' EXIT
}

add_finding() {
  printf '%s\n' "- check: $1" >>"$FINDINGS_FILE"
  printf '%s\n' "  file: $2" >>"$FINDINGS_FILE"
  if [ -n "${3:-}" ]; then
    printf '%s\n' "  line: $3" >>"$FINDINGS_FILE"
  fi
  printf '%s\n' "  text: $4" >>"$FINDINGS_FILE"
}

record_grep_output() {
  local check_name="$1"
  local line file rest line_no text
  # Parses grep -Hn output: "file:lineno:text". Colons in filenames would
  # corrupt the parse, but the paths scanned here make that effectively impossible.
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    file="${line%%:*}"
    rest="${line#*:}"
    line_no="${rest%%:*}"
    text="${rest#*:}"
    add_finding "$check_name" "$file" "$line_no" "$text"
  done
}

record_command_output() {
  local check_name="$1"
  local source_name="$2"
  local output="$3"
  while IFS= read -r line; do
    [ -n "$line" ] || continue
    add_finding "$check_name" "$source_name" "" "$line"
  done <<EOF
$output
EOF
}

scan_history() {
  local tmp matches=0
  tmp="$(mktemp)"
  grep -HniE "$PACKAGE_REGEX" \
    "$HOME/.bash_history" \
    "$HOME/.zsh_history" \
    "$HOME/.local/share/fish/fish_history" \
    >"$tmp" 2>/dev/null
  if [ -s "$tmp" ]; then
    matches=1
    record_grep_output "shell_history_package_reference" <"$tmp"
  fi
  rm -f "$tmp"
  return "$matches"
}

scan_npm_logs() {
  local tmp matches=0
  tmp="$(mktemp)"
  find "$HOME/.npm/_logs" -maxdepth 1 -type f -exec grep -HniE "$LOG_REGEX" {} + >"$tmp" 2>/dev/null
  if [ -s "$tmp" ]; then
    matches=1
    record_grep_output "npm_log_indicator" <"$tmp"
  fi
  rm -f "$tmp"
  return "$matches"
}

scan_tmp_files() {
  local path matches=0
  for path in /tmp/pglog /tmp/.pg_state; do
    if [ -e "$path" ]; then
      matches=1
      add_finding "tmp_artifact" "$path" "" "path exists"
    fi
  done
  return "$matches"
}

scan_processes() {
  local output
  # `pgrep` can match its own invocation on some platforms, so use `ps` consistently.
  # shellcheck disable=SC2009
  output="$(ps aux | grep -E "$PROCESS_REGEX" | grep -v 'grep -E' || true)"
  if [ -n "$output" ]; then
    record_command_output "process_indicator" "process list" "$output"
    return 1
  fi
  return 0
}

run_common_scans() {
  local found=0
  scan_history || found=1
  scan_npm_logs || found=1
  scan_tmp_files || found=1
  scan_processes || found=1
  return "$found"
}

print_results() {
  local found="$1"
  if [ "$found" -eq 0 ]; then
    printf 'all good\n'
  else
    printf 'findings:\n'
    cat "$FINDINGS_FILE"
  fi
}
