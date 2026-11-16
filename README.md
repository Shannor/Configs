# Configs

A place to store my configs for setting up different applications.

- VIM Config
- Homebrew Apps I use. 
- AI Prompts and Useful Projects
- reMarkable Paper Pro CLI and Agent Skills

Node is managed with asdf. Install global npm CLIs (e.g. `npm i -g cf`) with an asdf node active, then run `asdf reshim nodejs`.

## AI agent skills

- `ai/skills/<name>/SKILL.md`: shared skills, used by every agent (Claude, Codex, Pi, Copilot CLI, OpenCode, Antigravity/agy).
- `ai/overrides/<agent>/skills/<name>/`: optional per-agent replacement of a shared skill (see `ai/overrides/README.md`).
- `ai/setup-skills.sh [-n|--dry-run] [-f|--force]`: syncs shared skills to `~/.agents/skills` and links/copies them into each agent's skills directory.

## Links of note

- [Vim Rant](https://stevelosh.com/blog/2010/09/coming-home-to-vim/#using-the-leader)
