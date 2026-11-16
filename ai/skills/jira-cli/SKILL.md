---
name: jira-cli
description: Access Jira issues, sprints, boards, and epics via the Jira CLI tool installed at /opt/homebrew/bin/jira. Use when the user asks to look up, create, edit, list, or manage Jira tickets/issues, sprints, or boards.
---

# Jira CLI

The `jira` CLI tool is installed and configured at `/opt/homebrew/bin/jira`.
Configuration is at `~/.config/.jira/.config.yml`.

## Common Commands

### View an issue
```bash
jira issue view <ISSUE-KEY>
# Example: jira issue view EX-97
```

### List issues in current project
```bash
jira issue list
jira issue list --status "In Progress"
jira issue list -a "$(jira me)"   # assigned to me
```

### Create an issue
```bash
jira issue create
```

### Edit an issue
```bash
jira issue edit <ISSUE-KEY>
```

### Transition/move an issue
```bash
jira issue move <ISSUE-KEY> <STATE>
# Example: jira issue move EX-97 "In Progress"
```

### Comment on an issue
```bash
jira issue comment add <ISSUE-KEY> -b "Comment body"
```

### Sprints
```bash
jira sprint list
jira sprint list --state active
```

### Boards
```bash
jira board list
```

### Open in browser
```bash
jira open <ISSUE-KEY>
```

## Tips
- Use `--plain` flag for machine-readable output
- Use `-p <PROJECT>` to override the default project
- Use `--debug` for troubleshooting
- Run `jira <command> --help` for detailed usage of any command
