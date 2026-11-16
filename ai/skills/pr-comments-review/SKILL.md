---
name: pr-comments-review
description: >
  Interactively review, triage, address, and resolve pull request comments on Bitbucket or GitHub. Follows a disciplined review flow: survey all comments first without making changes, walk through each comment 1-by-1 to fix, defer to Jira, or note follow-up PRs, run tests, push changes, and post replies while marking comment threads resolved. Use when the user says "review pr comments", "check pr comments", "address pr comments", "resolve pr comments", or asks to address reviewer feedback on a pull request (use pr-review instead when performing a code review and leaving comments on an existing PR).
---

# PR Comments Review Skill

Systematically review, triage, address, test, push, and resolve comments on a Pull Request (PR) across Bitbucket (`bb`) or GitHub (`gh`).

---

## Core Philosophy

1. **Observe First, Never Edit Immediately**: On the initial pass, catalog and categorize every comment so the user has the complete landscape before touching any code.
2. **One-by-One Collaborative Decisions**: Walk through findings one at a time. Explain the exact line, root cause, and potential options (Fix now, Defer to Jira ticket, Note in follow-up PR, or Skip/Intended). Wait for user approval before making changes.
3. **Verify Every Step**: Run automated unit and integration tests after every change to catch regressions immediately.
4. **Close the Loop**: When changes are committed and pushed, reply to each review thread with specific details and resolve the comment thread via the CLI.

---

## Phase 1: Identify Platform, PR & Fetch Comments

### 1.1 Identify Hosting Platform & Tools
Check the git remote:
```bash
git remote get-url origin
```
- If `bitbucket.org` -> Platform is **Bitbucket**. Use `bb` CLI tool.
  - Verify CLI: `which bb` (ensure installed).
- If `github.com` -> Platform is **GitHub**. Use `gh` CLI tool.
  - Verify CLI: `which gh` (ensure installed).

### 1.2 Identify the PR
1. Determine current branch:
   ```bash
   git branch --show-current
   ```
2. Locate the PR:
   - **Bitbucket**:
     ```bash
     bb pr list -o json
     ```
     Find the PR matching the current source branch, or use `bb pr get <PR-ID> -o json`.
   - **GitHub**:
     ```bash
     gh pr view --json number,title,comments,reviewDecision
     ```

### 1.3 Fetch All Unresolved Comments
Fetch all comments including inline file/line comments, parent IDs, and resolution status:
- **Bitbucket**:
  ```bash
  bb pullrequest comment list --pullrequest <PR-ID> -o json
  ```
  Extract and parse parent comments (where `parent` is null or empty) and their inline location:
  - File path
  - Line number
  - Author / Reviewer
  - Resolution status (`resolution is not None`)
  - Content / Description
- **GitHub**:
  ```bash
  gh api graphql -f query='
  query($owner: String!, $repo: String!, $pr: Int!) {
    repository(owner: $owner, name: $repo) {
      pullRequest(number: $pr) {
        reviewThreads(first: 50) {
          nodes {
            id
            isResolved
            path
            line
            comments(first: 5) {
              nodes { id author { login } body }
            }
          }
        }
      }
    }
  }' -F owner=':owner' -F repo=':repo' -F pr=<PR-NUMBER>
  ```

---

## Phase 2: Initial Survey & Triage (Read-Only)

**RULE: Do NOT make any code edits during Phase 2.**

Present a clear, structured summary to the user:
1. **Summary / Status Reviews**: Any automated or bot summaries (e.g. Rovo Dev, Ensemble Reviews, CI summaries).
2. **High Severity / Blocking Comments**: Concurrency issues, resource leaks, data loss, unhandled panics, breaking architectural contracts.
3. **Logic & Runtime Bugs**: Unhandled nil pointers, type assertion errors, silent drop of data.
4. **API / Realtime Events**: Mismatched status codes, missing Pusher/WebSocket events, hanging client spinners.
5. **Maintainability / Style / Naming**: Shadowed identifiers, misplaced log lines, missing comments/docs.
6. **Test Coverage Gaps**: Missing test scenarios, misleading test fixtures.

For each item, summarize:
- The file & line number.
- The reviewer.
- A concise 2-sentence explanation of what is happening.
- The proposed solution or trade-offs.

---

## Phase 3: One-by-One Interactive Resolution

Go through comments **one at a time**:

### 3.1 For Each Comment:
1. Show the code context using `read` or file view.
2. Present the choices clearly:
   - **Option A / Option B**: Proposed code changes.
   - **Defer / Log to Jira**: If it belongs in a follow-up ticket (e.g., background cron reaper, broader refactor). Use `jira` CLI tool if available (`jira issue comment add <KEY> "..."` or view ticket).
   - **Covered in Stacked / Follow-up PR**: If a stacked feature branch already supersedes or refactors this area.
   - **Skip / Intended**: If the existing code is intentional or based on external constraints.
3. **Wait for user decision.**
4. If the user chooses to fix:
   - Make the minimal, clean edit.
   - Run relevant unit tests immediately (`go test`, `npm test`, etc.).
   - Add targeted test coverage if the comment highlighted missing tests.

---

## Phase 4: Stacked Branches Synchronization (if applicable)

If working on stacked branches (e.g., Feature A -> Feature B):
1. When Feature A is updated:
   - Check out Feature B: `git checkout <stacked-branch>`
   - Rebase onto Feature A: `git rebase <base-branch>`
   - Resolve any merge conflicts cleanly and keep test files in sync.
   - Run full test suite on the stacked branch.
   - Push to remote with `git push --force-with-lease`.
2. Inspect if new comments were raised on the stacked PR and repeat Phase 3.

---

## Phase 5: Verification, Commit & Push

1. Run the full test suite across all packages:
   ```bash
   go test -count=1 ./...
   ```
2. Check `git status` and `git diff` to ensure zero accidental changes or stray debugging logs.
3. Commit with a meaningful conventional commit message:
   ```bash
   git commit -m "fix(<scope>): address review feedback on <feature>

   - Bulleted summary of what was fixed and why.
   - Bulleted summary of tests added.

   Relates to <TICKET-ID>"
   ```
4. Push to remote:
   ```bash
   git push origin <branch>
   # or git push --force-with-lease origin <branch> if rebased
   ```

---

## Phase 6: Post Responses & Resolve Threads

**RULE: Never leave review comments hanging without an explanation.**

For every parent comment thread addressed:

### Bitbucket (`bb` CLI):
1. **Reply to the parent comment**:
   ```bash
   bb pullrequest comment create --pullrequest <PR-ID> --parent <COMMENT-ID> --comment "Fixed by [brief explanation of fix / commit / Jira ticket]."
   ```
2. **Resolve the comment thread**:
   ```bash
   bb pullrequest comment resolve --pullrequest <PR-ID> <COMMENT-ID>
   ```
3. **Verify resolution**:
   Ensure `resolution != None` on all parent threads.

### GitHub (`gh` CLI):
1. **Reply to the review thread**:
   ```bash
   gh pr comment <PR-NUMBER> --reply-to <COMMENT-ID> --body "Fixed by [brief explanation of fix / commit / Jira ticket]."
   ```
2. **Resolve the thread via GraphQL API**:
   ```bash
   gh api graphql -f query='
   mutation($threadId: ID!) {
     resolveReviewThread(input: { threadId: $threadId }) {
       thread { isResolved }
     }
   }' -F threadId="<THREAD-ID>"
   ```

---

## Checklist Before Completing

- [ ] All comments triaged and discussed with user.
- [ ] Code changes verified with automated tests passing 100%.
- [ ] New unit tests added for edge cases uncovered by reviews.
- [ ] Follow-up tasks or deferrals tracked in Jira / issue tracker.
- [ ] Changes committed and pushed to remote branch.
- [ ] Every parent comment thread replied to and marked resolved.
- [ ] Stacked downstream branches rebased and updated (if applicable).
