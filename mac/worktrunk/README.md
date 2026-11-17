# Worktrunk (`wt`) Configs

Reference configurations for [Worktrunk (`wt`)](https://worktrunk.dev/).

## Files

- [`config.toml`](./config.toml) — Global user config (lives at `~/.config/worktrunk/config.toml`). Explicitly configures sibling worktree directories (`{{ repo_path }}/../{{ repo }}.{{ branch | sanitize }}`) for IntelliJ / JetBrains Air compatibility (never nested in `.worktrees/`) and LLM commit message generation.
- [`wt.toml.example`](./wt.toml.example) — Project-level worktree config example from `oneTrickUI` (belongs at `<repo>/.config/wt.toml`). Runs `npm ci` before starting a new worktree and computes a deterministic localhost port per branch via `hash_port` for `wt list`.
