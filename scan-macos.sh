#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
. "$SCRIPT_DIR/canisterworm-common.sh"

init_findings

scan_launchagents() {
  local dir path matches=0
  for dir in \
    "$HOME/Library/LaunchAgents" \
    "/Library/LaunchAgents" \
    "/Library/LaunchDaemons"; do
    if [ -d "$dir" ]; then
      while IFS= read -r path; do
        matches=1
        add_finding "persistence_artifact" "$path" "" "path exists"
      done < <(find "$dir" -maxdepth 1 -name '*pgmon*' 2>/dev/null)
    fi
  done
  return "$matches"
}

scan_launchctl() {
  if ! command -v launchctl >/dev/null 2>&1; then
    return 0
  fi
  local output
  output="$(launchctl list 2>/dev/null | grep -i 'pgmon' || true)"
  if [ -n "$output" ]; then
    record_command_output "launchctl_match" "launchctl list" "$output"
    return 1
  fi
  return 0
}

found=0
run_common_scans || found=1
scan_launchagents || found=1
scan_launchctl || found=1
print_results "$found"
