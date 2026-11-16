---
name: wt-worktrees
description: >
  Explain how to use the `wt` (worktrunk) CLI tool for switching between Git worktrees,
  especially when multiple branches are stacked on top of each other. Use when the user
  asks about switching branches, managing stacked branches, navigating between worktrees,
  or running `wt` commands.
---

# wt (Worktrunk) — Stacked Branches & Worktree Navigation

The `wt` CLI manages parallel Git worktrees, letting you work on multiple branches simultaneously. This is essential when you have **stacked branches** (feature branches built on top of each other) and need to switch between them quickly.

## Installation & Setup

`wt` is installed at `/opt/homebrew/bin/wt`. Verify with:

```bash
wt --version
```

## Core Workflow for Stacked Branches

### 1. List All Worktrees

See every worktree and its status in one glance:

```bash
wt list
```

This shows branch names, worktree paths, and whether each branch has uncommitted changes or is ahead/behind its upstream.

### 2. Switch Between Worktrees

Switch to an existing branch's worktree:

```bash
wt switch <branch-name>
```

Go back to the **previous** worktree (like `cd -`):

```bash
wt switch -
```

Go to the **default** branch (main/master):

```bash
wt switch ^
```

### 3. Create a New Branch from the Current One

When stacking a new feature on top of the current branch:

```bash
wt switch --create <new-branch> --base=@
cd "$WT_WORKTREE"  # or cd into the worktree path shown in the output
```

`@` is a shortcut for the **current branch** as the base. This creates a new branch from wherever you currently are.

> **Note:** `wt switch --create` does **not** auto-cd into the new worktree. Use `cd "$WT_WORKTREE"` (shell variable set by wt) or `cd` into the path shown in the output.

### 4. Create a Branch from a Specific Base

```bash
wt switch --create <new-branch> --base <base-branch>
cd "$WT_WORKTREE"  # cd into the new worktree
```

Example — stack a hotfix on top of `release`:

```bash
wt switch release
wt switch --create hotfix-login --base=release
cd "$WT_WORKTREE"
```

## Interactive Picker

When you have many stacked branches, use the interactive picker:

```bash
wt switch
```

This opens a TUI with:
- **↑/↓** — Navigate branches
- **Type** — Filter branches by name
- **Enter** — Switch to selected worktree
- **Alt+c** — Create a new branch
- **Esc** — Cancel
- **1–5** — Toggle preview tabs (diff, log, ahead/behind, summary)

## Useful Shortcuts

| Shortcut | Meaning |
|----------|---------|
| `^` | Default branch (main/master) |
| `@` | Current branch |
| `-` | Previous worktree |
| `pr:123` | GitHub PR #123's branch |
| `mr:101` | GitLab MR !101's branch |

Examples:

```bash
wt switch pr:42          # Switch to PR #42's branch
wt switch -              # Back to previous worktree
wt switch ^              # Go to default branch
wt switch --create fix --base=@  # Stack on current branch
```

## Removing a Worktree

When you're done with a branch:

```bash
wt remove
```

This removes the worktree and deletes the branch if it's already merged.

## Managing Stacked Branches — Common Patterns

### Pattern 1: Review a Lower Branch

You're on a top branch and need to test/fix something on a lower stacked branch:

```bash
# See which branches exist
wt list

# Switch down to the lower branch
wt switch feature-auth

# Make your changes, commit, push

# Return to where you were
wt switch -
```

### Pattern 2: Rebase a Top Branch onto an Updated Lower Branch

```bash
# Switch to the branch you want to rebase onto
wt switch feature-auth

# Make changes, commit, push
git push

# Switch to the top branch
wt switch feature-api

# Rebase on top of the updated lower branch
git rebase feature-auth

# Force push if already pushed
git push --force-with-lease
```

### Pattern 3: Create a Chain of Stacked Branches

```bash
# Start from main
wt switch ^

# Create first feature branch
wt switch --create feature-auth --base=^
cd "$WT_WORKTREE"

# Stack second feature on top of it
wt switch --create feature-api --base=@
cd "$WT_WORKTREE"

# Stack a hotfix on top of that
wt switch --create hotfix-login --base=@
cd "$WT_WORKTREE"
```

### Pattern 4: Merge a Stack Back to Main

```bash
# Start from the top of the stack
wt switch feature-api

# Merge each branch bottom-up
wt merge feature-auth    # Merge lower branch first
wt merge feature-api     # Then merge the top branch
```

## Tips

- **Always check `wt list`** before switching to see what worktrees exist and their status.
- **Use `wt switch -`** to quickly bounce back and forth between two worktrees.
- **Use `--base=@`** when creating branches to stack on the current one — it's the most common pattern for stacked workflows.
- **Use the interactive picker** (`wt switch` with no args) when you have many branches and need to find the right one.
- **Run `wt switch <branch> --help`** for detailed usage of any command.
- **Use `--no-hooks`** to skip hook execution (useful for CI or automation).
- **Use `--format json`** for machine-readable output (e.g., in scripts or agent workflows).

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Branch doesn't exist | Use `wt switch --create <branch>` or `wt list --branches` |
| Path occupied | Another worktree is at the target path; switch to it or `wt remove` it first |
| Stale directory | Use `wt switch --clobber <branch>` to remove a non-worktree directory |
| Can't find the branch | Run `wt list --branches` to include branches without worktrees |
