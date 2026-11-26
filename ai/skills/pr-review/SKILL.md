---
name: pr-review
description: >
  Perform a thorough code review on an existing Pull Request on Bitbucket or GitHub,
  interactively curate draft inline and summary comments with the user, and post the
  review (inline comments, summary, approve, or request changes) via CLI. Use when the
  user says "review pr", "perform a review", "review pull request", "review PR #<id>",
  "leave a review", "code review PR", or wants to review an existing PR and post feedback
  (use pr-comments-review instead when addressing feedback left on your own PR).
---

# PR Review Skill

Perform a structured, high-signal code review on an existing Pull Request across Bitbucket (`bb`) or GitHub (`gh`), curate the findings interactively with the user, and post inline comments, summary feedback, and review status (`approve` / `request-changes` / `comment`).

---

## Core Philosophy

1. **Read-Only Analysis First, Never Post Unapproved Comments**: Analyze the PR completely and present all proposed inline comments, line references, and summary feedback to the user **before** posting anything to Bitbucket or GitHub.
2. **Never Disturb the Local Working Tree**: Inspect the PR via `git fetch` and `origin/<source-branch>` (or platform diff APIs) rather than checking out branches over dirty local work.
3. **Exact Line Number Verification**: Every inline comment must be anchored to the exact 1-indexed line number on the PR head commit (`--to <line>` on Bitbucket, `side: "RIGHT", line: <line>` on GitHub). Never guess line numbers from a stale local branch.
4. **High-Signal, Constructive Voice**: Focus on real bugs, architectural boundaries, security/authz, data integrity, and project conventions. Explain *why* something is an issue and suggest a concrete direction. Avoid noisy nitpicking unless asked.
5. **Interactive Curation**: Let the user approve, edit, drop, or add comments one-by-one or in batch before publishing the review.

---

## Phase 1: Identify Platform, Target PR & Context (Read-Only)

### 1.1 Detect Hosting Platform & CLI Tool
Inspect the git remote:
```bash
git remote get-url origin
```
- **`bitbucket.org`** -> Platform is **Bitbucket**. Verify `which bb`.
- **`github.com`** -> Platform is **GitHub**. Verify `which gh`.

### 1.2 Resolve the Target PR
If the user provided a PR ID/number, branch name, or URL, use it directly. Otherwise:
- **Bitbucket**:
  ```bash
  bb pr list -o json
  ```
- **GitHub**:
  ```bash
  gh pr list --json number,title,headRefName,baseRefName,author
  ```
If multiple open PRs could match and the target is ambiguous, list the candidates and ask the user which PR to review.

### 1.3 Fetch PR Metadata & Existing Comments
Fetch the PR details and any existing review threads so you do not duplicate feedback already left on the PR:

- **Bitbucket**:
  ```bash
  bb pr get <PR-ID> -o json
  bb pullrequest comment list --pullrequest <PR-ID> -o json
  ```
  Extract `title`, `description`, `author`, `source.branch.name`, `destination.branch.name`, and existing active comments (`inline.path`, `inline.to`, `content.raw`, `resolution`).

- **GitHub**:
  ```bash
  gh pr view <PR-NUMBER> --json number,title,body,author,headRefName,headRefOid,baseRefName,files,reviews,comments
  ```
  Also fetch existing inline review threads via GraphQL if needed so you know what has already been flagged.

### 1.4 Check Linked Ticket & Project Instructions
1. **Ticket Context**: If the PR title, description, or branch name references a YouTrack ticket (e.g., `OT-12`) or Jira ticket (e.g., `EX-305`):
   - **YouTrack (`OT-*`)**:
     ```bash
     /opt/homebrew/bin/youtrack issue view <TICKET-ID> --comments 10
     ```
   - **Jira (`EX-*`)**:
     ```bash
     /opt/homebrew/bin/jira issue view <TICKET-ID>
     ```
   Use the ticket description and acceptance criteria to verify the PR solves the right problem completely.
2. **Project Conventions**: Check `AGENTS.md` / `CLAUDE.md` and `.agents/skills/` in the repository so the review enforces repo-specific architecture and style standards.

### 1.5 Fetch Branches & Inspect the Diff Safely
Fetch the source and destination branches from `origin` without switching the current working branch:
```bash
git fetch origin <source-branch> <dest-branch>
```
1. Inspect the commit history and diff summary first:
   ```bash
   git log origin/<dest-branch>..origin/<source-branch> --oneline
   git diff origin/<dest-branch>...origin/<source-branch> --stat
   ```
2. For small PRs (<15 files), inspect the full unified diff:
   ```bash
   git diff origin/<dest-branch>...origin/<source-branch>
   ```
3. For large PRs (15+ files), review file-by-file or subsystem-by-subsystem:
   ```bash
   git diff origin/<dest-branch>...origin/<source-branch> -- <path/to/file>
   ```
4. To inspect full surrounding file context with **exact 1-indexed line numbers on the PR head commit**:
   ```bash
   git show origin/<source-branch>:<path/to/file> | nl -ba
   ```

---

## Phase 2: Deep Code Review & Analysis (Read-Only)

**RULE: Do NOT post any comments or modify local files during Phase 2.**

**Specialized Review Skills**:
- **Backend / Service Architecture**: Read and apply the **`hexagonal-architecture`** skill (`../hexagonal-architecture/SKILL.md`) when reviewing backend services, handlers, or repositories (Ports & Adapters boundaries, service-owned orchestration, plain value domain models over transport/DB DTO leakage, consumer-defined driven ports, and incremental Boy-Scout boundary hygiene).
- **Go (`.go` files in diff)**: Read and apply the **`golang-review`** skill (`../golang-review/SKILL.md`) to enforce idiomatic Go over Java/TypeScript patterns, Garbage Collector & pointer discipline (`[]T` over `[]*T`, avoiding unnecessary `*string`/value pointers), and `O(n^2)` / N+1 complexity checks.
- **React / TypeScript (`.ts` / `.tsx` files in diff)**: Read and apply the **`react-typescript-review`** skill (`../react-typescript-review/SKILL.md`) to enforce `children`/slot composition over pass-through prop drilling, flat early-return helpers over nested ternaries, thin components/loaders/actions backed by standalone pure functions, single-pass pure builders (no `.map()` side effects or repeated `.filter()` scans), direct use of generated OpenAPI types without redundant DTO re-mapping, named constants over magic numbers, named exports, and `import.meta.env.DEV` bundle hygiene.

Evaluate the changes across six dimensions:

1. **Correctness, Bugs & Edge Cases**
   - Unhandled errors, nil pointer dereferences, slice/map bounds, concurrency races, resource/goroutine leaks.
   - Partial failure states, transaction rollbacks, idempotency on retries, pagination/limit edge cases, and composite-key matching bugs (never falling back to an unrelated sibling record when an explicit sub-key doesn't match).
   - Database query correctness (N+1 queries, missing indexes on new filters, GORM v2 / Firestore pitfalls, zero-value updates, soft-delete handling).
2. **Performance, Complexity & Memory Efficiency**
   - Algorithmic complexity traps (`O(n^2)` nested linear scans instead of `O(n + m)` map lookups, string `+=` in loops, repeated slice shifting/sorting in loops, chained multi-pass `.filter()` scans, N+1 I/O).
   - Memory, GC & bundle pressure (unnecessary pointer indirection/heap escapes, `[]*T` vs `[]T`, missing slice/map capacity pre-allocation, dev-only UI/fixtures leaking into production client JS bundles).
3. **Architecture, Idioms & Project Conventions**
   - Hexagonal / Ports & Adapters boundaries: inward dependency direction, business orchestration in Application Services (not HTTP handlers), plain value domain structs (not leaking HTTP `api.*` or vendor DTOs into core services), and narrow consumer-defined driven ports (`Store` / `Gateway`) returning domain sentinel errors.
   - Frontend component composition & thin orchestrators: `children`/slots over pass-through prop drilling, standalone pure view-model builders and named handlers over bloated inline component/loader/action logic, no `.map()` side-effect mutations, and named exports everywhere.
   - Language-idiomatic design (e.g., idiomatic Go rather than Java/TypeScript abstractions; flat early-return functions instead of nested ternaries; named constants instead of magic numbers).
   - API & Adapter conventions (OpenAPI spec-first generation, trusting generated frontend SDK types directly instead of duplicating/re-mapping backend DTOs, status code mapping, explicit converters at backend boundaries).
   - Observability & logging (canonical/wide-event log rules, `xlog.Fields` / `clog.Fields` / `evlog` structured context, no PII, proper layer group names, no error-group logging inside services/DAOs).
   - Code style (decomposed helper methods and composable subcomponents over inline narrative comments or JSX variables).
4. **Security & Authorization**
   - Tenant/promoter isolation and `actor` scoping (`AuthorizedByUser` / `resolveUserID`).
   - Auth bypass risks, unvalidated external input, SQL injection in raw queries, secret exposure.
5. **Tests & Verification**
   - Are happy paths, failure paths, and authorization boundaries tested?
   - Do tests assert meaningful behavior rather than tautologies?
6. **Alignment with Ticket / Scope**
   - Does the implementation fulfill the ticket's acceptance criteria?
   - Are migrations, config changes, or backwards-compatibility concerns accounted for?

### Severity Classification
Classify each finding so the user can quickly prioritize:
- **[Blocking]**: Bugs, data loss/corruption, security/authz holes, broken API or architectural contracts.
- **[Suggestion]**: Architecture improvements, missing test coverage, maintainability, error-handling gaps.
- **[Nit / Question]**: Minor naming/style improvements, non-blocking observations, or clarifying questions for the author.

---

## Phase 3: Present Draft Review & Interactive Curation

**RULE: NEVER post comments or change PR approval status without explicit user confirmation.**

### 3.1 Present the Review Overview
Show the user a clear, scannable report:

1. **PR Overview**: PR ID, title, author, branch (`source -> dest`), linked ticket, and a 2-3 sentence summary of what the PR does.
2. **Recommended Verdict**: `Approve`, `Approve with comments`, `Comment only`, or `Request changes`.
3. **Draft Summary Comment** (optional top-level PR comment summarizing the review).
4. **Draft Inline Comments**: Number each proposed inline comment (`#1`, `#2`, ...) with:
   - **Location**: `<file-path>:<new-line-number>`
   - **Severity**: `[Blocking]`, `[Suggestion]`, or `[Nit / Question]`
   - **Code Context**: The 1-5 lines of code at that exact line on `origin/<source-branch>`
   - **Draft Comment**: Written in a direct, collaborative human tone (explain the issue/reasoning clearly and propose how to address it; avoid robotic boilerplate).

### 3.2 Curate with the User
Ask the user how they would like to proceed:
- **Review 1-by-1** (walk through each finding to keep, edit, or skip)
- **Batch selection** (e.g., *"Post all"*, *"Post #1, #2, #4 and drop #3"*, *"Reword #2 to say..."*)
- **Verdict selection**:
  - `Comment only` (post selected comments without changing approval state)
  - `Approve` (post selected comments + approve the PR)
  - `Request changes` (post selected comments + mark request-changes on the PR)

If the user edits a comment or asks to add a new inline comment on a specific file/line, verify the exact line number via `git show origin/<source-branch>:<file> | nl -ba` and confirm the updated text before posting.

---

## Phase 4: Post the Review via CLI

Once the user explicitly approves the final set of comments and verdict, publish them to the platform.

### 4.1 Bitbucket (`bb` CLI)

1. **Post Inline Comments** (write the body to a temp file first to avoid `/bin/bash` 3.2 heredoc-in-`$()` apostrophe parsing issues):
   - On a **new or context line** in the PR (most common — line number from `origin/<source-branch>:<file>`):
     ```bash
     cat <<'EOF' > /tmp/pr_comment.md
     <comment body>
     EOF
     bb pullrequest comment create \
       --pullrequest <PR-ID> \
       --file "<repo-relative-file-path>" \
       --to <NEW-LINE-NUMBER> \
       --comment "$(cat /tmp/pr_comment.md)" -o json
     rm -f /tmp/pr_comment.md
     ```
   - On a **deleted/removed line** (line number from `origin/<dest-branch>:<file>` that was removed in the diff):
     ```bash
     cat <<'EOF' > /tmp/pr_comment.md
     <comment body>
     EOF
     bb pullrequest comment create \
       --pullrequest <PR-ID> \
       --file "<repo-relative-file-path>" \
       --from <OLD-LINE-NUMBER> \
       --comment "$(cat /tmp/pr_comment.md)" -o json
     rm -f /tmp/pr_comment.md
     ```

2. **Post Top-Level Summary Comment** (if approved by user):
   ```bash
   cat <<'EOF' > /tmp/pr_comment.md
   <summary comment body>
   EOF
   bb pullrequest comment create \
     --pullrequest <PR-ID> \
     --comment "$(cat /tmp/pr_comment.md)" -o json
   rm -f /tmp/pr_comment.md
   ```

3. **Set Review Verdict** (only if requested by user):
   - **Approve**:
     ```bash
     bb pullrequest approve <PR-ID>
     ```
   - **Request Changes**:
     ```bash
     bb pullrequest request-changes <PR-ID>
     ```

### 4.2 GitHub (`gh` CLI)

On GitHub, submit all inline comments, the top-level review body, and the review event (`COMMENT`, `APPROVE`, or `REQUEST_CHANGES`) atomically in a single review call using `gh api`:

1. **Determine `owner/repo` and `headRefOid`**:
   ```bash
   gh pr view <PR-NUMBER> --json headRefOid,url
   ```
2. **Submit Bundled Review (Inline Comments + Summary + Verdict)**:
   ```bash
   gh api repos/{owner}/{repo}/pulls/<PR-NUMBER>/reviews \
     --method POST \
     --input - <<'EOF'
   {
     "commit_id": "<HEAD-COMMIT-SHA>",
     "body": "<top-level summary comment, or empty string>",
     "event": "COMMENT",
     "comments": [
       {
         "path": "<repo-relative-file-path>",
         "line": <NEW-LINE-NUMBER>,
         "side": "RIGHT",
         "body": "<inline comment body>"
       }
     ]
   }
   EOF
   ```
   - Set `"event"` to `"COMMENT"`, `"APPROVE"`, or `"REQUEST_CHANGES"` based on the user's chosen verdict.
   - For a comment on a deleted line on the base side, use `"side": "LEFT"` and the old line number.
   - If there are **no inline comments** (only a summary comment or verdict), you can use `gh pr review` directly:
     ```bash
     # Comment only
     gh pr review <PR-NUMBER> --comment --body "<summary>"

     # Approve (with optional body)
     gh pr review <PR-NUMBER> --approve --body "<summary>"

     # Request changes
     gh pr review <PR-NUMBER> --request-changes --body "<summary>"
     ```

---

## Phase 5: Confirmation Summary

After posting, display a clean summary to the user:
- PR URL (`https://bitbucket.org/<workspace>/<repo>/pull-requests/<PR-ID>` or GitHub PR URL)
- List of posted inline comments (`file:line` -> comment ID)
- Top-level summary comment status (if posted)
- Final review verdict (`Approved`, `Changes Requested`, or `Commented`)

---

## Checklist Before Completing

- [ ] Target PR metadata, diff, and existing comments fetched without dirtying the working tree.
- [ ] Linked YouTrack / Jira ticket and repo conventions (`AGENTS.md` / skills) checked.
- [ ] Every inline comment line number verified against `origin/<source-branch>:<file>`.
- [ ] All draft comments and the review verdict reviewed and approved by the user before posting.
- [ ] Comments and verdict posted via `bb` or `gh` CLI and confirmed with returned IDs/URLs.
