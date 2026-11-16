---
name: remarkable-books
description: Organize books in the Books folder on a reMarkable Paper Pro account via Cloud sync. Use when asked to audit or organize books, identify unorganized books, determine author names from filenames or front matter (first 5–10 pages), create author subfolders formatted as `Last Name, First Name`, move books into author folders, or manage the reMarkable Books directory over reMarkable Cloud.
---

# reMarkable Book Library Organization (Cloud & SSH)

Automated workflow for maintaining a structured book library in the `Books/` folder on a reMarkable account.

Books stored directly in the `Books/` folder are categorized into author subfolders formatted as **`Last Name, First Name`** (or `Last Name, First Name & Last Name, First Name` for co-authors).

---

## Transport Mode (Cloud vs. SSH)

- **Cloud Transport (Default & Primary)**: Operates seamlessly over reMarkable Cloud (`--transport cloud` or default). Does not require Developer Mode, SSH passwords, or being on the same local network. Changes (`mkdir`, `mv`, `rm`) automatically sync to the tablet over the air.
- **SSH Transport**: Used when working directly over local device Wi-Fi/USB. When making modifications over SSH, call `remarkable refresh` afterward to restart the `xochitl` UI on the physical tablet.

---

## Workflow Overview

1. **Scan `Books/` Directory**: List all documents directly inside `Books/` and list existing author subfolders.
2. **Identify Unorganized Books**: Find books not currently inside an author subfolder.
3. **Determine Author Name**:
   - Parse filename or title string.
   - If not found or ambiguous, inspect front matter (first 5–10 pages) using `pdftotext` or `remarkable read`.
4. **Format Author Directory Name**: Convert to `Last Name, First Name` (e.g., `Asimov, Isaac`, `Dreyfus, Hubert L.`).
5. **Create & Move**: Create the author subfolder if missing (`remarkable mkdir`), then move the book into it (`remarkable mv`).
6. **Sync Verification**: Cloud sync automatically pushes updates to the tablet. (If using SSH, run `remarkable refresh`).

---

## Detailed Step-by-Step Instructions

### Step 1: Scan `Books/` Folder

Retrieve library items in JSON format over Cloud transport:

```bash
remarkable ls --json
```

Or parse using Python:

```bash
python3 -c '
import json, subprocess

items = json.loads(subprocess.check_output(["remarkable", "ls", "--json"]))
books_folder = next((i for i in items if i.get("name") == "Books" and i.get("type") == "CollectionType"), None)

if not books_folder:
    print("Books folder not found.")
    exit(1)

books_id = books_folder["id"]
loose_books = [i for i in items if i.get("parent") == books_id and i.get("type") == "DocumentType"]
author_folders = [i for i in items if i.get("parent") == books_id and i.get("type") == "CollectionType"]

print(f"Author folders: {len(author_folders)}")
print(f"Unorganized books: {len(loose_books)}")
for b in loose_books:
    print(" -", b["name"])
'
```

- **Target directory**: `Books` (`CollectionType`)
- **Loose books**: Items where `parent == books.id` AND `type == "DocumentType"`
- **Existing author folders**: Items where `parent == books.id` AND `type == "CollectionType"`

---

### Step 2: Determine Author Name

#### 2a. Check Filename & Document Title

Many uploaded files embed author details in the document name:

- **`_OceanofPDF.com_<Title>_-_<Author_Name>.pdf`**:
  - Example: `_OceanofPDF.com_What_Computers_Cant_Do_..._-_Hubert_L_Dreyfus.pdf`
  - Author: `Hubert L. Dreyfus` → **`Dreyfus, Hubert L.`**
- **`<Author Name> - <Title>`** or **`<Title> - <Author Name>`**:
  - Example: `Asimov - Robots and Empire.pdf` → **`Asimov, Isaac`**
  - Example: `Political Ideologies - Andrew Heywood` → **`Heywood, Andrew`**

#### 2b. Check Front Matter (Pages 1–10)

If the filename does not clearly indicate the author's name, download the document or read the first 5–10 pages over Cloud:

- **Option A: Download PDF over Cloud and use `pdftotext` (Fastest for front matter inspection)**

```bash
cd /tmp
remarkable get "<Book Document Name>"
pdftotext -f 1 -l 10 "<Downloaded_File>.pdf" - | head -n 40
```

  *Note: `remarkable get` downloads the file to `<Document Name>.pdf`. Look for title page attributions like "By [Author]", "Written by [Author]", or copyright listings.*

- **Option B: Direct text read via Cloud CLI**

```bash
remarkable read "<Book Document Name>" --page 1
remarkable read "<Book Document Name>" --page 3
```

Clean up temporary files in `/tmp` after inspection.

#### 2c. Author Name Formatting Rules

- **Standard Single Author**: `First M. Last` → **`Last, First M.`**
  - `Hubert L. Dreyfus` → `Dreyfus, Hubert L.`
  - `Paul Mooney` → `Mooney, Paul`
  - `Jeff Wallace` → `Wallace, Jeff`
- **Co-Authors**: **`Last1, First1 & Last2, First2`**
  - `Noam Chomsky & Edward S. Herman` → `Chomsky, Noam & Herman, Edward S.`
- **Suffixes**: Keep suffix attached to last name.
  - `Martin Luther King, Jr.` → `King, Martin Luther, Jr.`
- **Match Existing Folders**: If an author subfolder already exists (e.g. `Orwell, George` or `Asimov, Isaac`), reuse the exact existing folder name to prevent duplicates.

---

### Step 3: Create Subfolder & Move Book

1. Check if subfolder `Books/<Last Name, First Name>` exists in `Books/`.
2. If it does **not** exist, create it via Cloud transport:

```bash
remarkable mkdir "Books/<Last Name, First Name>"
```

1. Move the loose document into the author subfolder:

```bash
remarkable mv "<Book Document Name>" "Books/<Last Name, First Name>"
```

---

### Step 4: Sync Verification

- **Over Cloud (Default)**: reMarkable Cloud automatically syncs folder creation and moved documents to the tablet wirelessly. No manual refresh needed.
- **Over SSH**: Run `remarkable refresh` to reload the device UI (`xochitl`).

---

## Example Execution Script / Agent Workflow (Cloud Transport)

```bash
# 1. Identify unorganized book
BOOK_NAME="_OceanofPDF.com_What_Computers_Cant_Do_The_Limits_of_Artificial_Intelligence_-_Hubert_L_Dreyfus.pdf"

# 2. Extract author: Hubert L. Dreyfus -> "Dreyfus, Hubert L."
TARGET_FOLDER="Dreyfus, Hubert L."
CLEAN_TITLE="What Computers Can't Do: The Limits of Artificial Intelligence"

# 3. Create folder via Cloud if missing
remarkable mkdir "Books/$TARGET_FOLDER"

# 4. Move book into author folder
remarkable mv "$BOOK_NAME" "$TARGET_FOLDER"

# 5. Optional: Rename to clean human-readable title
remarkable mv "$BOOK_NAME" "$CLEAN_TITLE"

# 6. Cloud sync handles the rest automatically over the air!
```
