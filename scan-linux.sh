#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
. "$SCRIPT_DIR/canisterworm-common.sh"

init_findings

scan_systemd_files() {
  local path matches=0
  for path in "$HOME/.config/systemd/user/pgmon.service" "$HOME/.local/share/pgmon/"; do
    if [ -e "$path" ]; then
      matches=1
      add_finding "persistence_artifact" "$path" "" "path exists"
    fi
  done
  return "$matches"
}

scan_systemctl() {
  local output found=0

  if ! command -v systemctl >/dev/null 2>&1; then
    return 0
  fi

  output="$(systemctl --user list-unit-files 2>/dev/null | grep -i 'pgmon' || true)"
  if [ -n "$output" ]; then
    found=1
    record_command_output "systemctl_unit_match" "systemctl --user list-unit-files" "$output"
  fi

  output="$(systemctl --user status pgmon.service 2>/dev/null || true)"
  if printf '%s' "$output" | grep -qi 'pgmon'; then
    found=1
    record_command_output "systemctl_status" "systemctl --user status pgmon.service" "$output"
  fi

  if [ "$found" -eq 1 ]; then
    return 1
  fi
  return 0
}

found=0

run_common_scans || found=1
scan_systemd_files || found=1
scan_systemctl || found=1
print_results "$found"
