---
name: remarkable-notes
description: Read, export, and transcribe handwritten notes, sketches, and annotations from the reMarkable Paper Pro tablet. Use when exporting notebook pages to PNG or SVG, reading highlights, extracting PDF/EPUB text, or processing handwritten pages with AI vision.
---

# reMarkable Notes & Handwriting

Workflows for extracting, reading, and processing handwritten notebooks, highlights, and document text from the reMarkable Paper Pro tablet using `remarkable`.

## Exporting Notebook Pages

Export notebook pages to PNG (default, best for AI vision / multimodal inspection) or SVG (best for vector rendering).

```bash
# Export all pages of a notebook to PNG in current directory
remarkable export "Meeting Notes"

# Export specific page to a custom directory
remarkable export "Meeting Notes" --page 3 -o /tmp/remarkable

# Export page as SVG
remarkable export "Architecture Diagram" --page 1 --svg -o /tmp/remarkable
```

Pages are saved using zero-padded filenames (e.g. `/tmp/remarkable/page_001.png`, `/tmp/remarkable/page_002.png`).

## AI Vision Workflow: Reading Handwritten Notes

To read or transcribe handwritten content:

1. Identify the target notebook and page number:

   ```bash
   remarkable pages "Project Brainstorm"
   ```

2. Export the specific page to a temporary directory:

   ```bash
   remarkable export "Project Brainstorm" --page 2 -o /tmp/rm-notes
   ```

3. Read or inspect the resulting image file:

   ```bash
   # Read the image using available vision tools or read tool
   /tmp/rm-notes/page_002.png
   ```

4. Transcribe or summarize the contents for the user.

## Live Screen Capture

Capture the tablet screen in real-time to see what the user is currently looking at or drawing:

```bash
# Save to default ./screenshot.png
remarkable screenshot

# Save to explicit destination
remarkable screenshot /tmp/rm-screen.png
```

Requires SSH transport.

## Extracting Document Highlights

The CLI can parse `.highlights/` metadata created when highlighting text inside PDFs or EPUBs on the device.

```bash
# Extract highlights across an entire document (JSON format)
remarkable highlights "Design Patterns"

# Extract highlights for a specific page
remarkable highlights "Design Patterns" --page 42

# Export highlights as clean Markdown blockquotes
remarkable highlights "Design Patterns" --markdown
```

Output with `--markdown` looks like:

```markdown
> "A design pattern is a general repeatable solution to a commonly occurring problem in software design."
*Page 14*

> "Favor object composition over class inheritance."
*Page 28*
```

Adjacent highlights are automatically merged (3-character gap tolerance). Requires SSH transport.

## Extracting Text from PDFs & EPUBs

Extract raw text directly from documents stored on the tablet without downloading the full document:

```bash
# Extract full text
remarkable read "System Architecture"

# Extract text for a single page
remarkable read "System Architecture" --page 12
```

- PDFs: parsed via `pdftotext` on the device or locally.
- EPUBs: parsed directly by the built-in parser.
- Works across both SSH and Cloud transports.

## Batch Processing Notebooks

To process multiple pages in an automated script:

```bash
#!/usr/bin/env bash
NOTEBOOK="Sprint Retro"
OUT_DIR="/tmp/rm-retro"
mkdir -p "$OUT_DIR"

remarkable export "$NOTEBOOK" -o "$OUT_DIR"

for img in "$OUT_DIR"/*.png; do
  echo "Processing $img..."
  # Run OCR, transcription, or indexing
done
```
