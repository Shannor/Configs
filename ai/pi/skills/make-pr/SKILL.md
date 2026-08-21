---
thinking: low
mdoel: claude-sonnet-4-6
description: >
  Squashes feature/bugfix branch commits into a single meaningful commit and creates a PR with a 
  comprehensive title and description. Use when the user says "make pr", "create pr", "squash and pr",
  "prepare pr", "open pr", "submit pr", "make a pull request", or any request to finalize a branch 
  into a pull request.
---

# Make PR Skill

Squash all commits on the current feature/bugfix branch into one well-crafted commit, then create a pull request with a meaningful title and description derived from the **why** and **how** of the changes.

---

## 1.0 GATHER CONTEXT

**PROTOCOL: Understand the full scope of work before writing anything.**

### 1.1 Identify the Branch and Base

1. Run `git branch --show-current` to get the current branch name.
2. Determine the base branch:
   - Run `git remote show origin 2>&1 | grep "HEAD branch"` to find the default branch.
   - If ambiguous, ask the user which branch to target.
3. Run `git log <base>..HEAD --oneline` to see all commits on this branch.
4. Run `git diff <base>...HEAD --stat` to see a summary of all files changed.
5. Check if the branch has been pushed to remote: `git branch -r | grep <branch>`
   - If found, note that a force push will be needed after squashing.

### 1.2 Detect Hosting Platform

1. Inspect the remote URL to determine if this is a GitHub or Bitbucket project:
   - Run `git remote get-url origin`
   - If the URL contains `github.com` — this is a **GitHub** project. Use `gh` CLI for PR creation.
   - If the URL contains `bitbucket.org` — this is a **Bitbucket** project. Use `bb` CLI for PR creation.
   - If the URL contains neither, ask the user which platform they are using.
2. Store the result as `PLATFORM` (`github` or `bitbucket`) for use in later steps.
3. Verify the required CLI tool is available:
   - **GitHub**: Run `which gh` — if not found, inform the user to install it (`brew install gh`) and HALT.
   - **Bitbucket**: Run `which bb` — if not found, inform the user to install it and HALT.

### 1.3 Extract Ticket Number

1. Inspect the branch name for a ticket/issue pattern. Common patterns:
   - `<PREFIX>-<NUMBER>` (e.g., `ex-11`, `JIRA-1234`, `GH-42`)
   - `feature/<PREFIX>-<NUMBER>-description`
   - `bugfix/<PREFIX>-<NUMBER>-description`
   - `fix/<PREFIX>-<NUMBER>-description`
2. If found, store it as `TICKET_ID` (e.g., `EX-11`). It will be prepended to the commit message and PR title.
3. If no ticket pattern is found, that is fine — proceed without one.

### 1.4 Find and Read the Plan (if one exists)

1. Check for a conductor plan associated with this work:
   - Look for `conductor/tracks.md` and find any in-progress `[~]` or recently completed `[x]` track.
   - If a matching track is found, check if its `plan.md` and `spec.md` files still exist on disk before reading them.
   - **NOTE:** The conductor workflow may have already deleted/archived the track folder. If the files are gone, note that the plan was completed and deleted — you will need to reconstruct the narrative from commits alone.
2. Also check for any `plan.md`, `PLAN.md`, or similar planning document in the repo root or `conductor/` directory.
3. If a plan is found and readable, use it as the **primary source of truth** for understanding the intent, scope, and structure of the work. The plan tells you the **why** — the commits and diffs tell you the **how**.
4. If no plan is found or it was already deleted, rely entirely on the commit history and diff to reconstruct the narrative.

### 1.5 Analyze the Changes

1. Read through all commit messages on the branch: `git log <base>..HEAD --format="%h %s%n%b---"`
   - This includes both subject lines and bodies, which often contain useful context.
2. Read the diff **summary** first: `git diff <base>...HEAD --stat`
   - **Do NOT read the full `git diff` for large changesets.** If there are more than ~15 files changed, use `--stat` to understand the scope and only read specific files of interest to understand key implementation decisions.
   - For smaller changesets (<15 files), reading the full diff is acceptable.
3. Synthesize this into:
   - **Type**: Is this a `feat`, `fix`, `refactor`, `chore`, `docs`, or `test`?
   - **Scope**: What area of the codebase does this touch? (e.g., `subscribers`, `auth`, `api`)
   - **Why**: What problem does this solve or what value does it add? Pull from the plan/spec if available.
   - **How**: What was the technical approach? Summarize the key implementation decisions.
   - **What changed**: List of meaningful changes grouped by concern, not by file.

---

## 2.0 COMPOSE THE COMMIT MESSAGE

**PROTOCOL: Write a single, comprehensive commit message.**

### 2.1 Format

The commit message MUST follow this structure:

```
<type>(<scope>): <concise summary> (<TICKET_ID>)

<body - the why and how, wrapped at 72 chars>

Closes: <TICKET_ID>
```

### 2.2 Rules

- **Subject line**: Max 72 characters. Use imperative mood ("add", "fix", "update", not "added", "fixed").
- **Ticket ID**: If `TICKET_ID` was extracted, append it in parentheses at the end: `fix(subscribers): add compact tag display for attendee cards (EX-11)`
- **Body**:
  - Start with **why** this change was made (1-2 sentences from the plan/spec or inferred from context).
  - Follow with **how** — a concise summary of the technical approach (key decisions, patterns used, architecture changes).
  - If a plan was used, reference the completed tasks briefly.
- **Footer**: Always include `Closes: <TICKET_ID>` to auto-close the ticket when merged.

### 2.3 Confirm with User

Present the drafted commit message to the user and ask for approval before proceeding.

---

## 3.0 SQUASH COMMITS

**PROTOCOL: Squash all branch commits into one.**

### 3.1 Safety Checks (run BEFORE squashing)

- **NEVER force-push to `main` or `master`**. Warn the user if they are on one of these branches and HALT.
- If there are uncommitted changes (`git status --short`), ask the user whether to include them in the squash or stash them first.
- If the branch has already been pushed to remote (detected in Step 1.1), inform the user that a force push (`git push --force-with-lease`) will be needed and ask for explicit confirmation before proceeding.

### 3.2 Perform the Squash

1. Count the commits: `git rev-list --count <base>..HEAD`
2. Perform a soft reset to the base: `git reset --soft <base>`
3. Stage all changes: `git add -A`
4. Create the new commit with the approved message: `git commit -m "<message>"`
5. Verify the result: `git log --oneline -3` and `git diff <base>...HEAD --stat`

---

## 4.0 CREATE THE PULL REQUEST

**PROTOCOL: Create a PR with a meaningful title and rich description. Use the correct CLI tool based on `PLATFORM` detected in Step 1.2.**

### 4.1 Push the Branch

1. Push the branch to remote:
   - If branch was NOT previously pushed: `git push -u origin <branch>`
   - If branch WAS previously pushed (squash rewrites history): `git push --force-with-lease origin <branch>`
2. Confirm the push succeeded.

### 4.2 Compose the PR

**Title format:**

```
<Concise description of the change> (<TICKET_ID>)
```

Example: `Fix form validation (ABC-123)`

**Body format:**

```markdown
## Summary

<2-4 bullet points covering the high-level what and why>

## Changes

<Group changes by concern, not by file. Use sub-bullets for details.>

### <Area 1, e.g., "Compact Tag Display">

- <What was done and why>
- <Key technical decisions>

### <Area 2, e.g., "Edit Subscriber Modal">

- <What was done and why>
- <Key technical decisions>

## How to Test

<Brief instructions for reviewers to verify the changes>

## Ticket

Closes <TICKET_ID>
```

### 4.3 Rules for the PR Body

- **Write from the plan's perspective** if a plan was used. The plan captures intent — translate it into reviewer-friendly language.
- **Focus on why before how**. Reviewers need to understand the motivation before the implementation.
- **Group by feature/concern**, not by file. A reviewer should understand what changed conceptually.
- **Keep it scannable**. Use headings, bullets, and short paragraphs. No walls of text.
- **Include testing instructions**. Even brief ones help reviewers verify.

### 4.4 Create the PR

Use the CLI tool determined by `PLATFORM` from Step 1.2.

**If `PLATFORM` is `github`** — use `gh`:

```bash
gh pr create --title "<title>" --body "$(cat <<'EOF'
<body content>
EOF
)"
```

**If `PLATFORM` is `bitbucket`** — use `bb`:

The `bb` CLI (bitbucket-cli) uses **different flags** than `gh`. Key differences:

- Uses `--description` instead of `--body`
- Requires `--source` (the branch name) — it does NOT auto-detect from the current branch
- Requires `--destination` (the base/target branch)

```bash
bb pr create \
  --title "<title>" \
  --source "<current branch>" \
  --destination "<base branch>" \
  --description "$(cat <<'EOF'
<body content>
EOF
)"
```

**IMPORTANT:** Run `bb pr create --help` first if you are unsure of the exact flags, as different versions of the `bb` CLI may have different syntax.

### 4.5 Return the PR URL

After creation:

- **GitHub (`gh`)**: The PR URL is printed directly in the output.
- **Bitbucket (`bb`)**: The output is a table with the PR ID. Construct the URL from the remote:
  - Extract workspace and repo from the remote URL: `git remote get-url origin`
  - Format: `https://bitbucket.org/<workspace>/<repo>/pull-requests/<PR_ID>`
  - Display this URL to the user.

---

## 5.0 PLAN CLEANUP

**PROTOCOL: Handle plan artifacts after PR creation.**

### 5.1 Check for Plan Files

If plan files were found and still exist on disk from Step 1.4 (e.g., `conductor/tracks/<track_id>/plan.md`, `conductor/tracks/<track_id>/spec.md`), determine if they should be cleaned up.

If the plan was already deleted/archived by the conductor workflow (common when using `/implement-track`), skip this section entirely — there is nothing to clean up.

### 5.2 Ask the User

Present the options:

1. **Remove in this PR** — Delete the plan files, commit the deletion, amend the squashed commit (only if NOT yet pushed) or add a follow-up commit, and update the PR.
2. **Follow-up PR** — Create a separate branch and PR that only removes the finished plan files. This keeps the feature PR clean.
3. **Keep** — Leave the plan files in the repo. Some teams prefer to keep them as historical records.

### 5.3 Execute the User's Choice

- **Remove in this PR**:
  - `git rm <plan files>`
  - `git commit -m "chore: remove completed plan for <track description>"`
  - Push and note in the PR description that plan cleanup is included.
- **Follow-up PR**:
  - Create a new branch from the current branch: `git checkout -b chore/cleanup-<track_id>-plan`
  - `git rm <plan files>`
  - `git commit -m "chore: remove completed plan for <track description>"`
  - `git push -u origin chore/cleanup-<track_id>-plan`
  - Create a PR using the platform CLI detected in Step 1.2:
    - **GitHub**: `gh pr create --title "chore: Remove completed plan for <track description>" --body "Cleanup of plan/spec files after <TICKET_ID or feature> was merged."`
    - **Bitbucket**: `bb pr create --title "chore: Remove completed plan for <track description>" --source "chore/cleanup-<track_id>-plan" --destination "<base branch>" --description "Cleanup of plan/spec files after <TICKET_ID or feature> was merged."`
  - Return to the original branch: `git checkout <original_branch>`
  - Return the cleanup PR URL.
- **Keep**: Do nothing.

---

## Key Reminders

- The **plan** is the source of truth for **why**. The **diff** is the source of truth for **how**.
- Always confirm the commit message with the user before squashing.
- Always confirm before force-pushing.
- Never force-push to main/master.
- The PR description should be useful to a reviewer who has zero context about the work.
- If no plan exists, reconstruct the narrative from commits and diffs — do not leave the PR description empty or generic.
- **Avoid reading the full diff for large changesets** — use `--stat` first, then targeted reads. Full diffs on 30+ files can blow up context.
- **Always run `--help` on the platform CLI** if a command fails with an unknown flag error, then retry with the correct syntax.
- **Always include `Closes: <TICKET_ID>`** in commit footer and `Closes <TICKET_ID>` in PR body to auto-close tickets when merged.
