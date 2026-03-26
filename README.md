# CanisterWorm Scanners

Simple Bash scripts for checking repositories and developer machines for indicators related to the CanisterWorm npm campaign.

## Files

- `scan-repos.sh`: scans one or more repo directories for known malicious package names and Trivy-related references
- `scan-macos.sh`: scans a macOS machine for shell history, npm logs, temp artifacts, and suspicious processes
- `scan-linux.sh`: scans a Linux machine for the same checks as macOS, plus `systemd` persistence indicators

## Requirements

- Bash
- Standard Unix tools: `find`, `grep`, `ps`
- Linux only: `systemctl` is used when available

## Usage

Make the scripts executable:

```bash
chmod +x scan-repos.sh scan-macos.sh scan-linux.sh
```

Scan repositories:

```bash
./scan-repos.sh /path/to/repos
./scan-repos.sh /path/to/repos /another/path
```

Scan a macOS machine:

```bash
./scan-macos.sh
```

Scan a Linux machine:

```bash
./scan-linux.sh
```

## Output

If nothing is found, the scripts print:

```text
all good
```

If something is found, the scripts print a structured findings list:

```text
findings:
- check: shell_history_package_reference
  file: /Users/example/.zsh_history
  line: 42
  text: npm install @teale.io/eslint-config
```

## Notes

- `scan-repos.sh` does not inspect `node_modules` or `.git`
- `scan-linux.sh` checks for `pgmon.service` and related paths used for Linux persistence
- These scripts are intended as lightweight IOC checks, not full malware analysis or remediation tools
