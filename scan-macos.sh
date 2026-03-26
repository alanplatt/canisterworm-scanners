#!/usr/bin/env bash

set -u

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
. "$SCRIPT_DIR/canisterworm-common.sh"

init_findings

found=0
run_common_scans || found=1
print_results "$found"
