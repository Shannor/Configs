---
name: remarkable
description: Master reference for the reMarkable Paper Pro CLI (remarkable). Use when setting up connections, running diagnostics (status), switching between Cloud and SSH transports, authenticating, or executing raw CLI commands on the tablet.
---

# reMarkable CLI Master Reference

Go CLI for the reMarkable Paper Pro tablet (`github.com/itsfabioroma/remarkable-cli`). Supports both reMarkable Cloud and local SSH transports, returning structured JSON for AI agents when running non-interactively.

Binary location: `~/.local/bin/remarkable` or system PATH.

## Connection & Setup

```bash
# Interactive wizard (Cloud auth first, optional SSH)
remarkable connect

# Cloud-only setup (works without developer mode)
remarkable connect --cloud-only

# SSH setup with saved IP and password (requires developer mode)
remarkable connect 192.168.1.5 --password "your-ssh-password"

# Add SSH to an existing cloud configuration
remarkable connect 192.168.1.5 --ssh-only

# Health check (SSH connectivity, Cloud auth, firmware, storage, doc count)
remarkable status
remarkable --json status

# Disconnect / purge saved credentials
remarkable disconnect
```

## Transport Hierarchy & Capabilities

The CLI auto-detects the best transport. Cloud is tried first; SSH is the power-user fallback (~1s latency, full device write access).

| Transport | Latency | Permissions     | Supported Operations                                                                                                                           |
|-----------|---------|-----------------|------------------------------------------------------------------------------------------------------------------------------------------------|
| **Cloud** | ~3s     | Read-only       | `ls`, `get`, `read`, `search`, `export` (read operations)                                                                                      |
| **SSH**   | ~1s     | Full Read/Write | All commands: `put`, `write`, `pages`, `tag`, `mkdir`, `rm`, `mv`, `splash`, `backup`, `watch`, `screenshot`, `highlights`, `fetch`, `refresh`  |

### Global Flags

```bash
--host <ip>          # Device IP address (default: 10.11.99.1 via USB)
--transport <mode>   # Transport selection: cloud (default), ssh, auto
--password <string>  # Device root SSH password
--key <path>         # SSH private key path (e.g. ~/.ssh/id_ed25519)
--json               # Enforce JSON output (default when stdout is not a TTY)
```

## Output & Error Handling

When executed by an agent, stdout defaults to structured JSON.

### Success Response Example

```json
{
  "status": "ok",
  "data": { ... }
}
```

### Error Response Example

```json
{
  "error": "SSH connection failed: host unreachable",
  "code": "transport_unavailable",
  "hint": "Check Wi-Fi IP or connect via USB cable (10.11.99.1)"
}
```

### Standard Error Codes

- `transport_unavailable`: Target transport (SSH/Cloud) is offline or unreachable.
- `not_found`: Document, page, or folder does not exist.
- `permission_denied`: SSH key/password invalid, or action requires developer mode SSH.
- `auth_required` / `auth_expired`: Cloud token missing or expired; run `remarkable auth`.
- `conflict`: Target document or destination folder already exists.
- `unsupported_operation`: Attempted write operation over Cloud transport.

## Quick Command Matrix

| Task               | Command                                          | Transport   |
|--------------------|--------------------------------------------------|-------------|
| Device Status      | `remarkable status`                              | Cloud + SSH |
| List library       | `remarkable ls [--all] [--tag <name>]`           | Cloud / SSH |
| Search documents   | `remarkable search "<query>"`                    | Cloud / SSH |
| Inspect metadata   | `remarkable info "<doc>"`                        | Cloud / SSH |
| Download PDF/EPUB  | `remarkable get "<doc>"`                         | Cloud / SSH |
| Upload document    | `remarkable put <file.pdf> ["Folder"]`           | SSH         |
| Fetch PDF from URL | `remarkable fetch <url> ["Folder"]`              | SSH         |
| Write text to page | `remarkable write "<doc>" --text "..."`          | SSH         |
| Export page image  | `remarkable export "<doc>" --page <n> [-o dir]`  | Cloud / SSH |
| Screen capture     | `remarkable screenshot [file.png]`               | SSH         |
| Text extraction    | `remarkable read "<doc>" [--page <n>]`           | Cloud / SSH |
| Highlights extract | `remarkable highlights "<doc>" [--markdown]`     | SSH         |
| Manage pages       | `remarkable pages [add\|rm\|move\|copy] "Doc"`   | SSH         |
| Tags               | `remarkable tag "Doc" "tag"` / `remarkable tags` | SSH         |
| Custom splash      | `remarkable splash set <image.png> [screen]`     | SSH         |
| Backup             | `remarkable backup [dir] [--raw]`                | SSH         |
| Live UI refresh    | `remarkable refresh`                             | SSH         |
| Watch hooks        | `remarkable watch --on-change "<cmd> {id}"`      | SSH         |
| SSH Key setup      | `remarkable setup-key`                           | SSH         |
