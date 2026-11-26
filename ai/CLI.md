# Useful CLI's for Agents/Models

CLI Tools seem to be the future for local development when using AI.
They have the benefit of not taking up Content Space and can be described in Skills or told to use by the Model.

## Required

### [Worktrunk (wt)](https://worktrunk.dev/)

CLI interface for managing different git worktrees. Super useful for having an open source tool
way of using it. No need for the harness, IDE or anything else to provide it.

IDEs are starting to add support for this natively, but it feels better to use this tool or instruct the AI too.

### [Agent-Browser](https://github.com/vercel-labs/agent-browser)

Before installing, check whether Node is managed by nvm or asdf. If so, install Agent-Browser with the project's Node package manager instead of Homebrew; the Homebrew formula also installs Homebrew's Node. Prefer adding it to `package.json` in team projects, using the existing lockfile to choose npm, pnpm, Yarn, or Bun. See the [browser-testing skill](skills/browser-testing/SKILL.md) for the detection and install steps.

## Nice to haves

### Some form of Git Provider CLI

### [Bitbucket CLI (bb)](https://github.com/gildas/bitbucket-cli)

Event X uses bitbucket so I need this personally. However Github and Gitlab have
way better CLIs.

### [YouTrack CLI](https://github.com/JetBrains/youtrack-cli)

Official JetBrains CLI (`brew install jetbrains/utils/youtrack`) used for One Trick (`OT`) issue tracking and Kanban workflows instead of GitHub Issues/Projects.

### [Jira CLI](https://github.com/ankitpokhrel/jira-cli)

Used for EventX Jira ticket management.

## PI Plugins

- [ PI Lens ]( https://pi.dev/packages/pi-lens )
- 