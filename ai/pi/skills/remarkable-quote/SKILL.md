---
name: remarkable-quote
description: Generate a Quote of the Day or themed quote selection from highlighted passages across books and documents on a reMarkable Paper Pro account. Use when asked for a quote of the day, daily quote, quotes from a specific book or document, or highlights from reMarkable reading.
---

# reMarkable Quote of the Day & Highlights

Workflow for extracting user-highlighted passages from reMarkable documents and generating a **Quote of the Day** or themed quote selection.

---

## Transport Mode (Cloud vs. SSH)

- **Cloud Transport (Default & Primary)**: Reads highlights directly over reMarkable Cloud (`--transport cloud` or default).
- **SSH Transport**: Supported when operating over local SSH.

---

## Workflow Overview

1. **Extract Highlights**:
   - From a specific book: `remarkable highlights "<Document Name>" --markdown`
   - Across the entire library: `remarkable highlights --all --markdown`
2. **Filter & Select**:
   - Filter out fragmented or partial text selections.
   - Select complete, impactful sentences or passages.
   - For single-book requests: Select from that document.
   - For "Quote of the Day": Select a random or topically relevant quote across highlighted books.
3. **Format Attribution**:
   - Format with markdown blockquotes, book title, author, and page number.

---

## Commands & Usage

### 1. Extract Highlights from a Specific Book

```bash
remarkable highlights "Political Ideologies: An Introduction" --markdown
```

### 2. Extract Highlights Across All Books & Documents

```bash
remarkable highlights --all --markdown
```

### 3. Extract Highlights in Structured JSON Format

```bash
remarkable highlights "<Document Name>" --json
```

---

## Example Output Format

### Quote of the Day

> **“Ideologies are thus not political philosophies but, rather, applied political philosophies.”**
>
> *— Andrew Heywood, Political Ideologies: An Introduction (Page 23)*

---

### Reading Selection

> **“Power tends to corrupt, and absolute power corrupts absolutely.”**
>
> *— Lord Acton / Andrew Heywood, Political Ideologies: An Introduction (Page 55)*

---

## Scripted Random Quote Generator

```bash
python3 -c '
import json, subprocess, random

# Fetch all highlights
out = subprocess.check_output(["remarkable", "highlights", "--all", "--json"])
items = json.loads(out)

# Collect all non-empty quotes
quotes = []
for doc in items:
    doc_name = doc.get("document", doc.get("name", "Unknown Document"))
    for h in doc.get("highlights", []):
        text = h.get("text", "").strip()
        page = h.get("page", 1)
        if len(text) > 30:  # Filter out very short/fragmented highlights
            quotes.append((text, doc_name, page))

if quotes:
    quote, doc_name, page = random.choice(quotes)
    print(f"\n> \"{quote}\"\n\n— {doc_name} (Page {page})")
else:
    print("No highlights found.")
'
```
