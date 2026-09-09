# reMarkable Paper Pro Tools & Skills

Configuration, documentation, and agent skills for managing the reMarkable Paper Pro e-ink tablet.

## Installed CLI Tools

Interacting with the reMarkable tablet and processing saved documents relies on two primary command-line tools:

### 1. `remarkable` (Device & Cloud CLI)

The primary interface for the tablet. Communicates with both reMarkable Cloud and local device SSH (Developer Mode).

- **Binary**: `~/.local/bin/remarkable` (in system `$PATH`)
- **Repository**: [`github.com/itsfabioroma/remarkable-cli`](https://github.com/itsfabioroma/remarkable-cli)
- **Install / Update**:

  ```bash
  go install github.com/itsfabioroma/remarkable-cli@latest
  # Or build from source:
  git clone https://github.com/itsfabioroma/remarkable-cli ~/.local/src/remarkable-cli
  cd ~/.local/src/remarkable-cli && go build -o remarkable .
  ln -sf ~/.local/src/remarkable-cli/remarkable ~/.local/bin/remarkable
  ```

- **Connection Setup**:

  ```bash
  remarkable connect                                     # interactive wizard (cloud + optional SSH)
  remarkable connect --cloud-only                        # cloud only (no SSH / dev mode)
  remarkable connect 10.11.99.1 --password "<password>"  # USB SSH setup
  remarkable connect 192.168.1.X --ssh-only              # Wi-Fi SSH setup
  remarkable status                                      # verify connectivity
  ```

- **Core Capabilities**:
  - Library management (`ls`, `search`, `mkdir`, `mv`, `rm`, `info`)
  - File transfers (`get`, `put`, `fetch` from URLs)
  - Pen-stroke writing engine (`write --text "..."`)
  - Screen capture (`screenshot`)
  - Page & notebook manipulation (`pages add`, `pages move`, `pages copy`)
  - Tag taxonomy (`tag`, `tags`)
  - Backups and change monitoring (`backup`, `watch`)
  - System splash screens (`splash set`, `splash restore`)
  - Immediate device screen reload (`refresh`)

### 2. `poppler` (`pdftotext`, `pdfinfo`, `pdfimages`) (Document Reader CLI)

The command-line suite used to read, inspect, and extract text and images from saved reMarkable PDF documents.

- **Binaries**: `/opt/homebrew/bin/pdftotext`, `/opt/homebrew/bin/pdfinfo`, `/opt/homebrew/bin/pdfimages`
- **Install**:

  ```bash
  brew install poppler
  ```

- **Why It Is Used**:
  - **Text Extraction**: `remarkable read "<doc>"` directly invokes `pdftotext` under the hood to extract searchable plain text from PDF documents stored on the tablet.
  - **Page Metadata**: `pdfinfo` inspects page counts, dimensions, and document formatting.
  - **Image & Drawing Extraction**: `pdfimages -png <file.pdf> <prefix>` extracts embedded annotations and raster assets from downloaded PDFs.
- **Common Usage**:

  ```bash
  # Extract text from a downloaded reMarkable PDF
  pdftotext -layout downloaded_notes.pdf notes.txt

  # Extract specific page text
  pdftotext -f 1 -l 1 -layout paper.pdf -

  # Inspect PDF metadata and page count
  pdfinfo paper.pdf
  ```

---

## Agent Skills (`skills/`)

The `skills/` folder contains modular Agent Skills compliant with the [Agent Skills standard](https://agentskills.io/specification):

| Skill                | Path                               | Description                                                                                                      |
| -------------------- | ---------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| **remarkable**       | `skills/remarkable/SKILL.md`       | Master reference for CLI commands, status, connection wizard, transports, and flags.                             |
| **remarkable-books** | `skills/remarkable-books/SKILL.md` | Organizing `Books/` library folder into author subfolders (`Last Name, First Name`) via front matter inspection. |
| **remarkable-docs**  | `skills/remarkable-docs/SKILL.md`  | Uploading/downloading files, fetching PDFs from URLs, folder hierarchy, tagging, and `remarkable refresh`.       |
| **remarkable-notes** | `skills/remarkable-notes/SKILL.md` | Exporting handwritten notes to PNG/SVG, multimodal vision workflows, screen capture, and highlights extraction.  |
| **remarkable-quote** | `skills/remarkable-quote/SKILL.md` | Extracting highlighted passages to generate a Quote of the Day or themed quote selection across books and docs.  |
| **remarkable-sync**  | `skills/remarkable-sync/SKILL.md`  | Automated backups, change detection (`watch`), splash screen customization, and SSH keys.                       |
| **remarkable-todos** | `skills/remarkable-todos/SKILL.md` | Reading handwritten `Daily Todo's`, auditing untracked/repeating tasks, and bridging to `satt tracker`.          |
| **remarkable-write** | `skills/remarkable-write/SKILL.md` | Writing text as native pen strokes onto notebook pages, page templates, and appending content.                   |

---

## Enabling Skills in Pi

Pi recursively discovers any directory containing a `SKILL.md`.

### Option 1: Configure in Pi Settings

Add this folder to your `~/.pi/agent/settings.json` or project settings:

```json
{
  "skills": [
    "/Users/shannortrotty/Documents/projects/Configs/remarkable/skills"
  ]
}
```

### Option 2: Symlink to Global Skills Directory

```bash
ln -s /Users/shannortrotty/Documents/projects/Configs/remarkable/skills/* ~/.pi/agent/skills/
```

---

## Common Workflows

### 1. Read Handwritten Notes with AI

```bash
# Export page as PNG
remarkable export "Sprint Planning" --page 1 -o /tmp/rm-notes

# Agent reads /tmp/rm-notes/page_001.png with vision tools to summarize or transcribe
```

### 2. Read Text from Downloaded PDF Documents

```bash
# Using remarkable CLI (calls pdftotext)
remarkable read "Research Paper" --page 5

# Or download and inspect directly with pdftotext
remarkable get "Research Paper"
pdftotext -layout "Research Paper.pdf" -
```

### 3. Send Summary or Notes to Tablet

```bash
# Write summary as native pen strokes on a new page
remarkable write "Daily Planner" --new-page --text "Meeting Summary:\n1. Architecture finalized\n2. Next release on Friday"
```

### 4. Fetch Web Paper and Refresh Screen

```bash
remarkable fetch https://arxiv.org/pdf/1706.03762.pdf "Research"
remarkable refresh
```
