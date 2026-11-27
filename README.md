# Configs

A place to store my configs for setting up different applications.

- VIM Config
- Homebrew Apps I use. 
- AI Prompts and Useful Projects
- reMarkable Paper Pro CLI and Agent Skills

Node is managed with asdf. Install global npm CLIs (e.g. `npm i -g cf`) with an asdf node active, then run `asdf reshim nodejs`.

## Local CLI utilities (`mac/bin/`)

Linked into `~/.local/bin/` via `mac/install.sh`:

- `clean-servers`: inspects and stops lingering frontend (`react-router dev`, `vite`, `next`, `esbuild`, `wt step tether`) and Go (`oneTrick`, `go run`, GoLand temp binaries) dev servers across Git and `~/.air/worktrees/temporary/*` worktrees while leaving WebStorm/GoLand language servers and ACP agents untouched.
  - `clean-servers` — interactive table preview (`[a]ll`, `[s]tale/non-main`, row numbers `1,3-5`, or `[q]uit`)
  - `clean-servers --list` — read-only table & Activity Monitor memory summary
  - `clean-servers --all` (or `-y`) — stop all running dev servers immediately
  - `clean-servers --stale -y` — stop all worktree / `~/.air` / orphaned dev servers, keeping `main` checkouts running
  - `clean-servers --older-than 4h -y` — stop dev servers running longer than 4 hours

## AI agent skills

- `ai/skills/<name>/SKILL.md`: shared skills, used by every agent (Claude, Codex, Pi, Copilot CLI, OpenCode, Antigravity/agy).
- `ai/overrides/<agent>/skills/<name>/`: optional per-agent replacement of a shared skill (see `ai/overrides/README.md`).
- `ai/setup-skills.sh [-n|--dry-run] [-f|--force]`: syncs shared skills to `~/.agents/skills` and links/copies them into each agent's skills directory.

## Links of note

- [Vim Rant](https://stevelosh.com/blog/2010/09/coming-home-to-vim/#using-the-leader)
