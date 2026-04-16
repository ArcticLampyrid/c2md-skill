---
name: convert-to-markdown
description: Convert documents, web pages, and images to Markdown through an isolated containerized MarkItDown backend. Use when an agent needs plain Markdown from files or URLs without touching the host Python environment.
---

# Convert to Markdown

Run:
```bash
scripts/convert-to-markdown.sh <file-path-or-uri> [file-path-or-uri ...]
```

Supported inputs:
- Local file paths
- `file://` URIs
- `http://` and `https://` URLs

Good fit for:
- PDF, DOCX, PPTX, XLSX, HTML
- Images and OCR-friendly sources
- Agent workflows that need deterministic Markdown output
