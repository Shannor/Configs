---
name: markdown-artifacts
description: >
  Format Markdown artifacts, walkthroughs, UI audits, and screenshot comparisons for standard
  Markdown readers (JetBrains Air, WebStorm, IntelliJ, GitHub). Enforces never using `carousel`
  code fences and always using standard Markdown headings and relative `./image.png` paths so
  embedded images render properly. Use whenever creating or editing Markdown artifacts or embedding
  screenshots/images.
---

# Standard Markdown Artifacts & Screenshot Embedding

The user's Markdown reader does **not** support custom ````carousel` code fences or bare root filesystem paths (`/Users/...`) for images. Always follow these rules whenever writing Markdown artifacts, walkthroughs, or screenshot comparisons:

## Core Rules

1. **Never Use `carousel` Code Fences**:
   - Do **not** wrap images or snippets in ````carousel ... ```` blocks or `<!-- slide -->` comments. Standard Markdown readers treat ````carousel` as a literal fenced code block, hiding every image inside raw text.
   - Instead, present sequential or before/after screenshots under clear Markdown headings (`### Before`, `### After`) or inside a standard GitHub Flavored Markdown table.

2. **Use Relative `./filename.png` Paths for Artifact Images**:
   - Save or copy all screenshots directly into the conversation's artifact directory (`<appDataDir>/brain/<conversation-id>/`) alongside the `.md` artifact file.
   - Reference images using relative paths (`./<filename>.png`), **not** absolute `/Users/...` paths, so JetBrains / CEF and standard Markdown previews resolve and display them reliably:
     ```markdown
     ### Before
     ![Mobile layout before changes](./mobile_before.png)

     ### After
     ![Mobile layout after changes](./mobile_after.png)
     ```
