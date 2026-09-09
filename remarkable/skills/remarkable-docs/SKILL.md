---
name: remarkable-docs
description: Manage documents, folders, tags, and library structure on the reMarkable Paper Pro tablet. Use when uploading PDFs/EPUBs, fetching web articles or research papers from URLs, moving or renaming documents, managing tags, or refreshing the device UI.
---

# reMarkable Document & Library Management

Workflows for organizing documents, directories, tags, and remote downloads on the reMarkable Paper Pro tablet using `remarkable`.

## Browsing & Searching Documents

```bash
# List documents (JSON format for scripts and agents)
remarkable ls

# Include trashed documents
remarkable ls --all

# Filter documents by tag
remarkable ls --tag "finance"

# Search documents by case-insensitive name matching
remarkable search "quarterly"

# Search with tag filter
remarkable search "roadmap" --tag "product"

# Inspect detailed metadata for a specific document
remarkable info "Q1 Strategy"
```

The `info` command returns:

- Name, internal UUID ID, and parent folder path
- Document type (`notebook`, `pdf`, `epub`)
- Page count
- Assigned tags
- Last modified timestamp

## Uploading & Downloading Documents

### Upload Local Files (`put`)

```bash
# Upload a PDF or EPUB to the root directory
remarkable put ~/Documents/contract.pdf

# Upload into a specific folder
remarkable put ~/Books/programming.epub "Reading List"
```

> **Important**: Uploaded documents require a device UI refresh (`remarkable refresh`) to appear immediately in the tablet interface.

### Download Documents (`get`)

```bash
# Download a document as PDF/EPUB to current directory
remarkable get "Meeting Notes"

# Works over both Cloud and SSH transports
```

### Fetch PDF directly from a URL (`fetch`)

Download directly from a web URL and stream it to the tablet in a single command:

```bash
# Fetch arXiv paper to root
remarkable fetch https://arxiv.org/pdf/2401.12345.pdf

# Fetch whitepaper directly into a folder
remarkable fetch https://example.com/spec.pdf "Research"
```

Direct PDF links only. Automatically triggers upload.

## Folders & Library Organization

```bash
# Create a new folder
remarkable mkdir "Architecture"

# Create nested folder structure
remarkable mkdir "Projects/Client-A"

# Move a document into a folder
remarkable mv "Draft RFC.pdf" "Architecture"

# Rename a document
remarkable mv "Old Name" "New Name"

# Delete a document or folder (moves to trash or removes permanently)
remarkable rm "Obsolete Spec"
```

## Tag Management

Organize notebooks and individual pages with searchable tags:

```bash
# Tag a document
remarkable tag "Q1 Planning" "urgent"

# Remove a tag from a document
remarkable tag "Q1 Planning" "urgent" --rm

# Tag a specific page within a notebook
remarkable tag "Work Log" "follow-up" --page 4

# List all tags across the entire tablet library
remarkable tags
```

## Critical Step: Refresh Device UI (`remarkable refresh`)

When making modifications via SSH (`put`, `mkdir`, `mv`, `rm`, `fetch`), the device's internal UI service (`xochitl`) does not always re-index the filesystem dynamically.

Always run `refresh` after write operations:

```bash
remarkable refresh
```

This restarts `xochitl` (~2 seconds) so newly uploaded files, created folders, and deleted documents immediately reflect on the e-ink screen without rebooting the tablet.

## Example Agent Workflow: Download and File a Paper

```bash
# 1. Ensure destination folder exists
remarkable mkdir "AI Research"

# 2. Fetch paper from web
remarkable fetch https://arxiv.org/pdf/1706.03762.pdf "AI Research"

# 3. Tag document
remarkable tag "1706.03762" "transformers"

# 4. Refresh screen UI so user sees the new paper
remarkable refresh
```
