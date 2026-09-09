---
name: remarkable-write
description: Write text, notes, outlines, and summaries directly onto reMarkable Paper Pro notebook pages as native pen strokes. Use when appending text to existing pages, drafting notes, creating blank or templated pages, or pushing AI summaries to the tablet.
---

# reMarkable Text & Page Writing

Workflows for drafting and pushing text directly onto reMarkable Paper Pro notebooks as native pen strokes (Fineliner simulation) using `remarkable write` and `remarkable pages`.

> **Requirement**: Writing onto pages and modifying notebook structure requires active **SSH access** (device in Developer Mode).

## Writing Text onto Pages

The CLI converts plain text into vector pen strokes using a clean handwritten Fineliner aesthetic. It automatically wraps text and scales font size based on text length:

```bash
# Append text to the end of an existing page
remarkable write "Daily Planner" --text "Review architectural proposal with team at 2 PM"

# Write onto a specific existing page (appends below existing strokes)
remarkable write "Project Ideas" --page 2 --text "Action Items:\n- Benchmark SQLite performance\n- Draft RFC"

# Create a brand new page at the end of the notebook and write onto it
remarkable write "Quick Notes" --new-page --text "Summary of meeting on March 10th..."
```

### Auto-Scaling Rules

- **Short text** (< 80 chars): Large, prominent heading-style text.
- **Medium paragraphs**: Standard note-taking size, neatly aligned.
- **Multi-line / long text**: Word-wrapped, compact font to fit page margins comfortably.
- **Newlines**: Preserved using literal `\n`.

## Managing Notebook Pages

Before or after writing, manage notebook pages using `remarkable pages`:

```bash
# List all pages and their metadata in a notebook
remarkable pages "Architecture Decisions"

# Append a blank page to the end
remarkable pages add "Architecture Decisions"

# Add a page with a specific template
remarkable pages add "Architecture Decisions" --template "P Grid medium"

# Insert a page after a specific page number
remarkable pages add "Architecture Decisions" --after 4 --template "P Lined medium"

# Delete a page
remarkable pages rm "Architecture Decisions" --page 5

# Reorder pages within a notebook
remarkable pages move "Architecture Decisions" --page 4 --to 2
```

### Popular Built-in Templates

Use exact template names when creating pages:

- `Blank` (default clean slate)
- `P Grid medium` (portrait medium grid)
- `P Grid small` (portrait fine grid)
- `P Lined medium` (portrait ruled lines)
- `P Dot medium` (portrait bullet journal dot grid)
- `P Checklist` (portrait task list)
- `P Dayplanner` (daily planning layout)
- `P Margin medium` (Cornell-style left margin)

## Cross-Notebook Page Operations

Move or copy existing pages across notebooks:

```bash
# Copy page 3 from "Scratchpad" into "Archive"
remarkable pages copy "Scratchpad" --page 3 --to "Archive"

# Move (transfer and remove from source) page 2 to another notebook
remarkable pages move-to "Scratchpad" --page 2 --to "Project Backlog"
```

## Agent Workflows

### 1. Pushing Daily Digest / Standup Notes

```bash
SUMMARY="Standup Notes (2025-03-11)\n- Finished auth module\n- Reviewing PR #42\n- Next: Database migrations"

# Check if "Daily Notes" exists
if remarkable info "Daily Notes" >/dev/null 2>&1; then
  remarkable write "Daily Notes" --new-page --text "$SUMMARY"
else
  # Document doesn't exist yet: upload or create page
  remarkable write "Daily Notes" --new-page --text "$SUMMARY"
fi
```

### 2. Appending Task Checklist to Active Page

```bash
remarkable write "Tasks" --page 1 --text "- [x] Fix CORS configuration\n- [ ] Deploy to staging"
```

### 3. Immediate Visual Verification

After writing, capture a screenshot or export the page to verify appearance:

```bash
remarkable export "Daily Notes" --page 1 -o /tmp/verify
```
