---
name: remarkable-todos
description: Inspect and transcribe handwritten Daily To-dos from reMarkable notebooks (e.g., `Daily Todo's`), identify uncompleted, untracked, or repeating tasks across daily pages, and bridge them into task tracking systems like `satt tracker`. Use when asked to review daily to-dos, read handwritten tasks on reMarkable, audit untracked or repeating tasks, or sync reMarkable to-dos with `satt tracker`.
---

# reMarkable Handwritten To-Dos & Task Tracking (`satt`)

Automated workflow for transcribing handwritten daily to-dos from a reMarkable tablet, auditing uncompleted or repeating tasks, and bridging them into the `satt tracker` CLI tool.

---

## Transport Mode (Cloud vs. SSH)

- **Cloud Transport (Default & Primary)**: Exports notebook pages to PNG directly over reMarkable Cloud (`--transport cloud` or default).
- **SSH Transport**: Supported when operating over local SSH.

---

## Workflow Overview

1. **Locate & Export Pages**:
   - Find the primary to-do notebook (default: `Daily Todo's` or searched via `remarkable search "todo"`).
   - Export recent notebook pages to PNG format in `/tmp/rm-todos/`.
2. **Transcribe & Classify Tasks (AI Vision)**:
   - Read exported PNG image(s) using AI vision.
   - Classify items into:
     - ⚪ **Open / Uncompleted**: Empty checkboxes, uncrossed bullet points, or starred items.
     - ✅ **Completed**: Checked checkboxes or items with strikethrough lines.
     - 🔁 **Repeating / Rollover**: Items appearing across multiple daily pages without completion.
3. **Cross-Reference with `satt tracker`**:
   - Fetch active tracked goals from `satt`:

     ```bash
     satt tracker goals list
     satt tracker project list
     ```

   - Identify **Untracked Tasks**: Handwritten items on reMarkable not yet present in `satt tracker`.
4. **Bridge to `satt tracker`**:
   - Add new untracked tasks into `satt`:

     ```bash
     satt tracker goals add "<Task Name>"
     ```

   - Triage goals if needed: `satt tracker goals triage`.
5. **Clean Up**: Remove temporary `/tmp/rm-todos/` PNG files.

---

## Detailed Step-by-Step Instructions

### Step 1: Export Recent Notebook Pages

Locate the notebook and export recent pages to PNG format:

```bash
# Export specific page (e.g., latest page) to /tmp/rm-todos
mkdir -p /tmp/rm-todos
remarkable export "Daily Todo's" --page 186 -o /tmp/rm-todos

# Or export the last 3 pages for rollover analysis
remarkable export "Daily Todo's" --page 184 -o /tmp/rm-todos
remarkable export "Daily Todo's" --page 185 -o /tmp/rm-todos
remarkable export "Daily Todo's" --page 186 -o /tmp/rm-todos
```

---

### Step 2: Transcribe Handwritten Tasks with Vision

Inspect the exported `/tmp/rm-todos/page_*.png` images using vision tools.

Record:

- Date / Page number heading
- List of open tasks
- List of completed tasks
- Rollover items (written on multiple days)

---

### Step 3: Audit Against `satt tracker`

Fetch existing tracked goals:

```bash
satt tracker goals list
```

Compare transcribed handwritten tasks against the `satt tracker` goals list:

- **Untracked Tasks**: Highlighted tasks found on the reMarkable page that have no matching goal in `satt tracker`.
- **Repeating / Stale Tasks**: Tasks appearing on consecutive days that haven't been completed or promoted to an active goal.

---

### Step 4: Sync / Add Tasks to `satt tracker`

For untracked tasks approved by the user, add them directly to `satt tracker`:

```bash
# Add a new goal
satt tracker goals add "<Task Name>"

# View goal details or triage
satt tracker goals view "<goal_id>"
satt tracker goals triage
```

---

## Example Audit Report Format

### 📝 Handwritten To-Do Audit (`Daily Todo's` — Page 186)

**Open Tasks Discovered**:

1. ⚪ *Refactor Auth0 code separation* — (Status: Open on tablet)
2. ⚪ *Review Contentful Dry-Run Script* — (Status: Open on tablet)
3. ⚪ *Buy coffee beans* — (Status: Open on tablet — **Untracked in `satt`**)

**Repeating / Stale Tasks** (Appearing across Pages 184–186):

- 🔁 *Review Contentful Dry-Run Script* (Carried over 3 days)

**Recommended `satt` Actions**:

```bash
satt tracker goals add "Buy coffee beans"
```
