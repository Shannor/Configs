#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/pi/skills"
HUB_DIR="$HOME/.agents/skills"

DRY_RUN=0
FORCE=0

SYMLINK_TARGETS=(
  "$HOME/.claude/skills"
  "$HOME/.codex/skills"
  "$HOME/.pi/skills"
  "$HOME/.pi/agent/skills"
)

if [ -d "$HOME/.config/opencode" ]; then
  SYMLINK_TARGETS+=("$HOME/.config/opencode/skills")
fi

# Antigravity / Gemini CLI traverse directories without following symlinked skill folders.
COPY_TARGETS=(
  "$HOME/.gemini/antigravity-cli/skills"
  "$HOME/.gemini/config/skills"
)

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Sync custom skills from this repo to ~/.agents/skills/ (preserving third-party
skills installed there), then symlink/copy all skills to supported AI agents.

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
        "$HUB_DIR"/*)
          log "prune broken symlink: $entry -> $link_target"
          if [ "$DRY_RUN" -eq 0 ]; then
            rm "$entry"
          fi
          ;;
      esac
    fi
  done
}

propagate_skill() {
  local skill_name="$1"
  local hub_path="$2"
  local copy_src="${3:-$hub_path}"
  local target_dir

  for target_dir in "${SYMLINK_TARGETS[@]}"; do
    link_skill "$hub_path" "$target_dir/$skill_name"
  done

  for target_dir in "${COPY_TARGETS[@]}"; do
    sync_dir "$copy_src" "$target_dir/$skill_name"
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
  for target_dir in "${SYMLINK_TARGETS[@]}" "${COPY_TARGETS[@]}"; do
    mkdir -p "$target_dir"
  done
fi

for skill_dir in "$SOURCE_DIR"/*; do
  [ -d "$skill_dir" ] && [ -f "$skill_dir/SKILL.md" ] || continue
  skill_name="$(basename "$skill_dir")"
  sync_dir "$skill_dir" "$HUB_DIR/$skill_name"
done

for target_dir in "${SYMLINK_TARGETS[@]}"; do
  prune_broken_links "$target_dir"
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
