---
name: youtrack-cli
description: Access YouTrack issues, Kanban boards, projects, comments, and links via the official YouTrack CLI installed at /opt/homebrew/bin/youtrack. Use whenever looking up, creating, editing, listing, linking, or transitioning tickets/issues (e.g., OT-* tickets on One Trick).
---

# YouTrack CLI (`youtrack`)

The official JetBrains `youtrack` CLI is installed at `/opt/homebrew/bin/youtrack`.
Configuration is stored at `~/.config/youtrack/config.json` (active instance: `https://gruntt.youtrack.cloud`).

For full up-to-date flag/subcommand documentation bundled with the installed CLI version, run:
```bash
/opt/homebrew/bin/youtrack skill guide youtrack-cli
/opt/homebrew/bin/youtrack skill guide youtrack-cli references/commands
/opt/homebrew/bin/youtrack skill guide youtrack-cli references/gotchas
```

---

## One Trick (`OT`) Project Conventions

- **Project Key:** `OT` (`One Trick`) — Kanban Board URL: `https://gruntt.youtrack.cloud/agiles/218-1/current`
- **Kanban Column Field (`Stage`, NOT `State`):**
  `Backlog` -> `Ready` -> `In Progress` -> `In Review` -> `Done`
- **Repository / Area Field (`Subsystem`):**
  - `Backend` (`Shannor/OneTrick`)
  - `UI` (`Shannor/OneTrickUI`)
  - `Full-Stack` (cross-repo features)
  - `Scripts` (`Shannor/OneTrick-Scripts`)
- **Board Sync:** Every issue created in `OT` automatically appears on `One Trick Kanban Board` in its `Stage` column. Do **not** create GitHub Issues for One Trick repos.

---

## Common Commands

### View an issue (with recent comments & links)
```bash
/opt/homebrew/bin/youtrack issue view <ISSUE-ID> --comments 10
/opt/homebrew/bin/youtrack issue link list <ISSUE-ID>
# Example: youtrack issue view OT-11 --comments 10
```

### List issues on the Kanban board
```bash
# All unresolved issues in OT with Stage & Subsystem columns
/opt/homebrew/bin/youtrack issue list --query "project: OT #Unresolved" --fields "idReadable,Stage,Subsystem,summary"

# Filter by Stage or Subsystem
/opt/homebrew/bin/youtrack issue list --query "project: OT Stage: Ready" --fields "idReadable,Subsystem,summary"
/opt/homebrew/bin/youtrack issue list --query "project: OT Subsystem: UI #Unresolved" --fields "idReadable,Stage,summary"
```

### Create an issue (atomic Stage, Subsystem, tags & Markdown description)
```bash
cat <<'EOF' | /opt/homebrew/bin/youtrack issue create \
  --project OT \
  --summary "feat(session): short summary" \
  --custom-fields '{"Stage":"Backlog","Subsystem":"Backend"}' \
  --tag enhancement \
  --description-file -
## Summary
...
EOF
```

### Transition Kanban `Stage` or update `Subsystem`
Prefer `issue field set` when values contain spaces (`In Progress`, `In Review`):
```bash
/opt/homebrew/bin/youtrack issue field set OT-12 Stage --value "In Progress"
/opt/homebrew/bin/youtrack issue field set OT-12 Stage --value "In Review"
/opt/homebrew/bin/youtrack issue field set OT-12 Stage --value "Done"
/opt/homebrew/bin/youtrack issue field set OT-12 Subsystem --value "UI"
```
*(Or via YouTrack command syntax with braces: `youtrack issue command OT-12 "Stage {In Progress}"`.)*

### Update summary or description
```bash
cat <<'EOF' | /opt/homebrew/bin/youtrack issue update OT-12 --description-file -
Updated markdown body...
EOF
```

### Add a comment
```bash
cat <<'EOF' | /opt/homebrew/bin/youtrack issue comment create OT-12 --text-file -
Implemented in PR #82.
EOF
```

### Link related or dependent issues
```bash
# List link types (185-0 = Relates, 185-1 = Depend [source is required for target], 185-3 = Subtask)
/opt/homebrew/bin/youtrack issue link type list
/opt/homebrew/bin/youtrack issue link add OT-11 --target OT-12 --type 185-1
```

## Safety & Scripting Tips
- Use `--json` (or `--plain`) for scripting and pipe through `jq` when narrowing JSON fields.
- Use `--dry-run` to preview write requests without mutating YouTrack data.
- Never guess flags — run `/opt/homebrew/bin/youtrack <group> --help` if unsure.
