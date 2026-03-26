# CanisterWorm Scanners

Simple Bash scripts for checking repositories and developer machines for indicators related to the CanisterWorm npm campaign.

## Files

- `scan-repos.sh`: scans one or more repo directories for known malicious package names and Trivy-related references
- `scan-macos.sh`: scans a macOS machine for shell history, npm logs, temp artifacts, suspicious processes, LaunchAgent persistence, C2 domain connections, and npm credential exposure
- `scan-linux.sh`: scans a Linux machine for the same checks as macOS, plus `systemd` persistence indicators

## Requirements

- Bash
- Standard Unix tools: `find`, `grep`, `ps`
- macOS: `lsof`, `dscacheutil`, `launchctl` are used when available
- Linux only: `lsof`, `systemctl` are used when available

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
All good
```

If something is found, the scripts print a structured findings list:

```text
findings:
- check: shell_history_package_reference
  file: /Users/example/.zsh_history
  line: 42
  text: npm install @teale.io/eslint-config
```

## What is checked

| Check | scan-macos.sh | scan-linux.sh | scan-repos.sh |
|---|---|---|---|
| 67 known malicious npm packages (repo files) | | | ✅ |
| Shell history references to malicious packages | ✅ | ✅ | |
| npm log indicators | ✅ | ✅ | |
| Temp artifacts (`/tmp/pglog`, `/tmp/.pg_state`) | ✅ | ✅ | |
| Running `pgmon`/`pglog`/`service.py` processes | ✅ | ✅ | |
| C2 domain (`tdtqy-oyaaa-aaaae-af2dq-cai.raw.icp0.io`) in hosts/connections/DNS | ✅ | ✅ | |
| `~/.npmrc` auth token present (rotate if compromised) | ✅ | ✅ | |
| LaunchAgent/LaunchDaemon persistence (`pgmon`) | ✅ | | |
| systemd persistence (`pgmon.service`) | | ✅ | |
| Trivy CI/CD references | | | ✅ |

## Notes

- `scan-repos.sh` does not inspect `node_modules` or `.git`
- `npmrc_token_present` is a risk indicator, not proof of compromise — it means harvestable credentials existed on the machine; rotate your npm tokens if you have any other findings
- These scripts are intended as lightweight IOC checks, not full malware analysis or remediation tools
