---
name: remarkable-sync
description: Automate tablet backups, monitor document changes with event hooks, customize splash screens, and manage SSH authentication on the reMarkable Paper Pro. Use when creating device backups, setting sleep/poweroff screens, watching for changes, or configuring SSH keys.
---

# reMarkable Sync, Automation & Maintenance

Workflows for automating device backups, reactive change monitoring, splash screen customization, and SSH credential management for the reMarkable Paper Pro tablet using `remarkable`.

## Structured Backups

Create complete backups of documents, preserving folder hierarchies and rendering notebook pages to high-resolution PNG images:

```bash
# Standard backup into ./remarkable-backup/
remarkable backup

# Custom destination backup
remarkable backup ~/Backups/remarkable-$(date +%Y-%m-%d)

# Raw backup of internal xochitl directory (compressed tar.gz archive)
remarkable backup ~/Backups/raw --raw
```

- **Structured mode**: Iterates through library folders, downloads PDFs/EPUBs directly, and converts notebook pages to PNG.
- **Raw mode**: Dumps `/home/root/.local/share/remarkable/xochitl/` for bit-for-bit restoration.
- Requires SSH transport.

## Change Monitoring & Reactive Automation (`watch`)

Monitor the device for document edits, additions, or pen stroke updates, and execute custom shell hooks when changes occur:

```bash
# Watch for modifications and print the changed document ID
remarkable watch --on-change "echo 'Document updated: {id}'"

# Trigger an automatic backup or sync script on edit
remarkable watch --on-change "./sync_document.sh {id}"
```

The `{id}` placeholder is automatically replaced with the UUID of the modified document.
Useful for background daemon scripts or agents maintaining real-time parity between tablet notes and a local Git / Obsidian vault.

## Custom Splash Screens

Customize the e-ink sleep, poweroff, and reboot screens. Images are automatically scaled and converted to the Paper Pro's native resolution (1620x2160 pixels):

```bash
# Inspect currently installed screens
remarkable splash list

# Replace default sleep screen (suspended state)
remarkable splash set ~/Pictures/wallpaper.png

# Replace specific system screens
remarkable splash set ~/Pictures/shutdown.png poweroff
remarkable splash set ~/Pictures/booting.png starting
remarkable splash set ~/Pictures/lowbattery.png battery
remarkable splash set ~/Pictures/restart.png reboot

# Restore official factory default splash screens
remarkable splash restore
```

Supported screen targets:

- `sleep` (default suspended screen)
- `poweroff` (powered down)
- `starting` (boot splash)
- `battery` (battery depleted)
- `reboot` (rebooting)

Requires SSH transport.

## SSH Security & Passwordless Key Setup

### Install SSH Public Key (`setup-key`)

Install your local SSH public key (e.g., `~/.ssh/id_ed25519.pub`) onto the reMarkable tablet to enable passwordless authentication:

```bash
remarkable setup-key
```

Once installed, SSH transport commands will authenticate instantly without prompting or reading saved passwords.

### Change Device SSH Password

Update the device root password from the CLI:

```bash
remarkable password "NewSecurePassword123"
```

## Maintenance & Updates

```bash
# Check overall device health, disk space, and firmware version
remarkable status

# Update the remarkable binary to the latest release
remarkable update
```
