#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/skills"
OVERRIDES_DIR="$SCRIPT_DIR/overrides"
HUB_DIR="$HOME/.agents/skills"

DRY_RUN=0
FORCE=0

# Targets are "agent:skills-dir". The agent name selects per-agent overrides in
# overrides/<agent>/skills/<skill>, which replace the shared skill for that agent only.
SYMLINK_TARGETS=(
  "claude:$HOME/.claude/skills"
  "codex:$HOME/.codex/skills"
  "pi:$HOME/.pi/skills"
  "pi:$HOME/.pi/agent/skills"
  "copilot:$HOME/.copilot/skills"
)

if [ -d "$HOME/.config/opencode" ]; then
  SYMLINK_TARGETS+=("opencode:$HOME/.config/opencode/skills")
fi

# Antigravity (agy) traverses directories without following symlinked skill folders.
COPY_TARGETS=(
  "agy:$HOME/.gemini/antigravity-cli/skills"
  "agy:$HOME/.gemini/config/skills"
)

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Sync shared skills (ai/skills) to ~/.agents/skills/ (preserving third-party
skills installed there), then symlink/copy all skills to supported AI agents
(Claude, Codex, Pi, Copilot CLI, OpenCode, Antigravity). Per-agent overrides in
ai/overrides/<agent>/skills/<skill> replace the shared skill for that agent.

Options:
  -n, --dry-run   Show changes without modifying files
  -f, --force     Replace existing non-symlink directories in symlink targets
  -h, --help      Show this help message
EOF
}

log() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[dry-run] %s\n' "$*"
  else
    printf '%s\n' "$*"
  fi
}

sync_dir() {
  local src="$1"
  local dest="$2"

  if [ -L "$dest" ]; then
    log "replace symlink -> copy: $dest"
    if [ "$DRY_RUN" -eq 0 ]; then
      rm "$dest"
      mkdir -p "$dest"
      rsync -a --delete --exclude='.DS_Store' "$src/" "$dest/"
    fi
  elif [ ! -d "$dest" ]; then
    log "install: $dest"
    if [ "$DRY_RUN" -eq 0 ]; then
      mkdir -p "$dest"
      rsync -a --delete --exclude='.DS_Store' "$src/" "$dest/"
    fi
  elif ! diff -qr -x '.DS_Store' "$src" "$dest" >/dev/null 2>&1; then
    log "update: $dest"
    if [ "$DRY_RUN" -eq 0 ]; then
      rsync -a --delete --exclude='.DS_Store' "$src/" "$dest/"
    fi
  fi
}

link_skill() {
  local src="$1"
  local dest="$2"

  if [ -L "$dest" ]; then
    if [ "$(readlink "$dest")" = "$src" ]; then
      return 0
    fi
    log "relink: $dest -> $src"
    if [ "$DRY_RUN" -eq 0 ]; then
      ln -sfn "$src" "$dest"
    fi
  elif [ -e "$dest" ]; then
    if [ "$FORCE" -eq 1 ]; then
      log "replace dir -> symlink: $dest -> $src"
      if [ "$DRY_RUN" -eq 0 ]; then
        rm -rf "$dest"
        ln -s "$src" "$dest"
      fi
    else
      log "skip (existing non-symlink, pass --force to replace): $dest"
    fi
  else
    log "link: $dest -> $src"
    if [ "$DRY_RUN" -eq 0 ]; then
      mkdir -p "$(dirname "$dest")"
      ln -s "$src" "$dest"
    fi
  fi
}

prune_broken_links() {
  local target_dir="$1"
  [ -d "$target_dir" ] || return 0

  local entry link_target
  for entry in "$target_dir"/*; do
    [ -L "$entry" ] || continue
    if [ ! -e "$entry" ]; then
      link_target="$(readlink "$entry")"
      case "$link_target" in
        "$HUB_DIR"/*|"$OVERRIDES_DIR"/*)
          log "prune broken symlink: $entry -> $link_target"
          if [ "$DRY_RUN" -eq 0 ]; then
            rm "$entry"
          fi
          ;;
      esac
    fi
  done
}

override_path() {
  local agent="$1"
  local skill_name="$2"
  local path="$OVERRIDES_DIR/$agent/skills/$skill_name"
  if [ -f "$path/SKILL.md" ]; then
    printf '%s' "$path"
  fi
}

propagate_skill() {
  local skill_name="$1"
  local hub_path="$2"
  local copy_src="${3:-$hub_path}"
  local entry agent target_dir override

  for entry in "${SYMLINK_TARGETS[@]}"; do
    agent="${entry%%:*}"
    target_dir="${entry#*:}"
    override="$(override_path "$agent" "$skill_name")"
    link_skill "${override:-$hub_path}" "$target_dir/$skill_name"
  done

  for entry in "${COPY_TARGETS[@]}"; do
    agent="${entry%%:*}"
    target_dir="${entry#*:}"
    override="$(override_path "$agent" "$skill_name")"
    sync_dir "${override:-$copy_src}" "$target_dir/$skill_name"
  done
}

# Skills that exist only as an agent override (no shared version).
propagate_override_only() {
  local entry agent target_dir skill_dir skill_name

  for entry in "${SYMLINK_TARGETS[@]}" "${COPY_TARGETS[@]}"; do
    agent="${entry%%:*}"
    target_dir="${entry#*:}"
    for skill_dir in "$OVERRIDES_DIR/$agent/skills"/*; do
      [ -d "$skill_dir" ] && [ -f "$skill_dir/SKILL.md" ] || continue
      skill_name="$(basename "$skill_dir")"
      [ -f "$SOURCE_DIR/$skill_name/SKILL.md" ] && continue
      if printf '%s\n' "${COPY_TARGETS[@]}" | grep -qxF "$entry"; then
        sync_dir "$skill_dir" "$target_dir/$skill_name"
      else
        link_skill "$skill_dir" "$target_dir/$skill_name"
      fi
    done
  done
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -n|--dry-run)
      DRY_RUN=1
      ;;
    -f|--force)
      FORCE=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

if [ ! -d "$SOURCE_DIR" ]; then
  printf 'Source skills directory not found: %s\n' "$SOURCE_DIR" >&2
  exit 1
fi

if [ "$DRY_RUN" -eq 0 ]; then
  mkdir -p "$HUB_DIR"
  for entry in "${SYMLINK_TARGETS[@]}" "${COPY_TARGETS[@]}"; do
    mkdir -p "${entry#*:}"
  done
fi

for skill_dir in "$SOURCE_DIR"/*; do
  [ -d "$skill_dir" ] && [ -f "$skill_dir/SKILL.md" ] || continue
  skill_name="$(basename "$skill_dir")"
  sync_dir "$skill_dir" "$HUB_DIR/$skill_name"
done

for entry in "${SYMLINK_TARGETS[@]}"; do
  prune_broken_links "${entry#*:}"
done

for skill_dir in "$HUB_DIR"/*; do
  [ -d "$skill_dir" ] && [ -f "$skill_dir/SKILL.md" ] || continue
  skill_name="$(basename "$skill_dir")"
  # On dry-run, copy targets should preview against repo source if the repo skill has pending updates.
  if [ "$DRY_RUN" -eq 1 ] && [ -f "$SOURCE_DIR/$skill_name/SKILL.md" ]; then
    propagate_skill "$skill_name" "$skill_dir" "$SOURCE_DIR/$skill_name"
  else
    propagate_skill "$skill_name" "$skill_dir"
  fi
done

propagate_override_only

if [ "$DRY_RUN" -eq 1 ]; then
  for skill_dir in "$SOURCE_DIR"/*; do
    [ -d "$skill_dir" ] && [ -f "$skill_dir/SKILL.md" ] || continue
    skill_name="$(basename "$skill_dir")"
    if [ ! -d "$HUB_DIR/$skill_name" ]; then
      propagate_skill "$skill_name" "$HUB_DIR/$skill_name" "$skill_dir"
    fi
  done
fi

log "Skills setup complete."
