---
name: git-commit
description: >
  Generate Git commit messages adhering strictly to Chris Beams' 7 Rules of Git Commit Messages. Use when writing, generating, reviewing, or prompting for Git commit messages.
---

# Git Commit Message Skill (cbeams standard)

This skill governs how to compose high-quality Git commit messages following Chris Beams' gold-standard guide, *"How to Write a Git Commit Message"*.

A well-crafted Git commit message is the best way to communicate context to fellow developers and future maintainers. A diff tells you **what** changed, but only the commit message can properly tell you **why**.

---

## 1.0 THE SEVEN RULES AT A GLANCE

1. **Separate subject from body with a blank line**
2. **Limit the subject line to 50 characters** (50 soft limit, 72 hard limit)
3. **Capitalize the subject line**
4. **Do not end the subject line with a period**
5. **Use the imperative mood in the subject line**
6. **Wrap the body at 72 characters**
7. **Use the body to explain *what* and *why* vs. *how***

---

## 2.0 STANDARD COMMIT TEMPLATE

```text
Summarize changes in around 50 characters or less

More detailed explanatory text, if necessary. Wrap it to about 72
characters or so. In some contexts, the first line is treated as the
subject of the commit and the rest of the text as the body. The
blank line separating the summary from the body is critical (unless
you omit the body entirely); various tools like `log`, `shortlog`
and `rebase` can get confused if you run the two together.

Explain the problem that this commit is solving. Focus on why you
are making this change as opposed to how (the code explains that).
Are there side effects or other unintuitive consequences of this
change? Here's the place to explain them.

Further paragraphs come after blank lines.

 - Bullet points are okay, too

 - Typically a hyphen or asterisk is used for the bullet, preceded
   by a single space, with blank lines in between, but conventions
   vary here

If you use an issue tracker, put references to them at the bottom,
like this:

Resolves: #123
See also: #456, #789
```

---

## 3.0 WORKFLOW FOR GENERATING COMMITS

**PROTOCOL: Always analyze context before writing the commit message.**

### Step 1: Gather Git Context

1. Run `git status` to see staged and unstaged files.
2. If files are not staged, ask the user or stage relevant files as appropriate.
3. Run `git diff --cached` (or `git diff` if examining working tree changes) to inspect the actual changes.
   - For large diffs (>15 files), run `git diff --cached --stat` first to understand the scope, then inspect key modified files.
4. Run `git log -n 5 --oneline` to check existing repository conventions (e.g. ticket prefix formats).

### Step 2: Analyze the Intent

Ask and answer the following questions from the code diff:

- **What is the core problem being solved?**
- **Why is this change necessary?**
- **How did the code behave before, and what was wrong with that?**
- **How does it behave now, and why was this approach chosen?**
- **Are there any side effects, breaking changes, or manual steps needed?**
- **Are there related issue IDs or PR references?**

### Step 3: Compose the Subject Line (Rules 1–5)

1. **Imperative Mood Test**:
   The subject line MUST complete the sentence:
   > *If applied, this commit will* **`<your subject line here>`**

   - **Correct (Imperative)**:
     - `Refactor subsystem X for readability`
     - `Update getting started documentation`
     - `Remove deprecated API methods`
     - `Release version 1.0.0`
     - `Fix failing CompositePropertySourceTests`
   - **Incorrect (Do NOT use)**:
     - `Fixed bug with Y` (past tense / indicative)
     - `Changing behavior of X` (present participle / gerund)
     - `More fixes for broken stuff` (vague noun phrase)

2. **Formatting Constraints**:
   - Start with a **Capital letter**.
   - Do **NOT** place a period `.` at the end.
   - Aim for **50 characters or less**. (72 is the absolute maximum before GitHub/Git UIs truncate with ellipses `...`).
   - If you cannot summarize the change under 50 chars, consider whether the commit contains too many unrelated changes and should be split into **atomic commits**.

3. **Blank Line Separation**:
   - Always place a single blank line between the subject and the body.

### Step 4: Compose the Body (Rules 6–7)

1. **Focus on WHAT and WHY, not HOW**:
   - The diff already shows *how* the code was rewritten. Use the body to explain context, motivation, choices, and trade-offs.
   - Contrast the prior state with the new state when helpful.

2. **Line Wrapping**:
   - Hard wrap all body lines at **72 characters**. Git does not wrap text automatically. Wrapping at 72 chars ensures `git log` indents nicely within an 80-column terminal.

3. **Lists & Bullet Points**:
   - Use hyphen `-` or asterisk `*` preceded by a single space.
   - Separate bullet items or paragraphs with blank lines.

4. **Issue Tracking References**:
   - Put issue/ticket references at the bottom of the body.
   - Format: `Resolves: #123`, `Fixes: #456`, `See also: #789`.

### Step 5: Present or Execute

- Present the constructed commit message to the user for review.
- If requested, run `git commit -m "..."` (or use a temporary file / heredoc with `git commit -F` to preserve proper multi-line formatting and wrapping).

---

## 4.0 DETAILED BREAKDOWN OF THE SEVEN RULES

### Rule 1: Separate subject from body with a blank line

Git subcommands like `git log --oneline`, `git shortlog`, `git rebase`, and `git format-patch` rely on the first line as the commit title. Without a blank line, Git treats the whole message as a single continuous block, corrupting summaries and email patches.

*Single-line commits:* Simple, trivial changes (e.g. `Fix typo in introduction to user guide`) do not require a body. If no context is needed, a single imperative line is sufficient.

### Rule 2: Limit the subject line to 50 characters

50 characters is a rule of thumb that forces concise summaries. GitHub's UI truncates subject lines at 72 characters. Strive for 50, treat 72 as hard max.

### Rule 3: Capitalize the subject line

Begin all subject lines with a capital letter:

- `Accelerate to 88 miles per hour` (Good)
- `accelerate to 88 miles per hour` (Bad)

### Rule 4: Do not end the subject line with a period

Trailing punctuation in subject lines is unnecessary and wastes precious space.

- `Open the pod bay doors` (Good)
- `Open the pod bay doors.` (Bad)

### Rule 5: Use the imperative mood in the subject line

The imperative mood gives a command ("Clean your room", "Close the door"). Git itself uses imperative mood when generating automatic commits (`Merge branch 'feature'`, `Revert "Add the thing"`).

Always test with: **"If applied, this commit will [YOUR SUBJECT LINE]"**

### Rule 6: Wrap the body at 72 characters

Git never wraps body text automatically. Manually line-wrap at 72 characters so that when Git indents logs in terminal views, everything stays clean under 80 columns.

### Rule 7: Use the body to explain what and why vs. how

Re-establishing code context is expensive. Code comments explain complex implementation details; commit body text explains business intent, motivation, trade-offs, and historical context.

Example of a stellar commit body (from Bitcoin Core):

```text
Simplify serialize.h's exception handling

Remove the 'state' and 'exceptmask' from serialize.h's stream
implementations, as well as related methods.

As exceptmask always included 'failbit', and setstate was always
called with bits = failbit, all it did was immediately raise an
exception. Get rid of those variables, and replace the setstate
with direct exception throwing (which also removes some dead
code).

As a result, good() is never reached after a failure (there are
only 2 calls, one of which is in tests), and can just be replaced
by !eof().

fail(), clear(n) and exceptions() are just never called. Delete
them.
```

---

## 5.0 QUICK CHECKLIST BEFORE COMMITTING

- [ ] Subject line is under 50 characters (max 72).
- [ ] Subject line starts with a capital letter.
- [ ] Subject line does NOT end with a period.
- [ ] Subject line is in imperative mood (completes "If applied, this commit will...").
- [ ] Blank line separates subject line from body.
- [ ] Body lines are wrapped at 72 characters.
- [ ] Body explains **why** the change was made and **what** problem it solves (not just how).
- [ ] Ticket/issue references are placed at the bottom.
