---
name: rfp-pdf-extraction
description: Extracts structured text from RFP documents (PDF, DOCX) with special handling for Czech diacritics, tables, and scanned pages. Use when you have a PDF or DOCX input document and need clean UTF-8 text with page markers and tables preserved. Output is markdown with `## Page N` separators. Runs via `uv run` — no manual venv needed.
---

# RFP PDF/DOCX Extraction

## When to use

- User provided a `.pdf` or `.docx` RFP document.
- Native Read of the PDF returns no text or garbled output (scanned / image PDF).
- Document contains tables you need to preserve (priced items, requirements matrices).
- Document is in Czech and you need correct NFC-normalized diacritics.

If the PDF is simple text-only and OpenCode's native Read tool works, prefer that — it's zero-overhead.

## What you get

A markdown file with:
- `## Page N` headers per source page
- Body text in UTF-8, NFC-normalized
- Tables formatted as markdown tables (best effort from `pdfplumber.extract_tables()`)
- Header / footer stripped (repeating lines)

## How to run

```bash
# From the skill directory (OpenCode will cd there automatically when invoking the skill)
uv run --script resources/extract.py \
  --input /path/to/rfp.pdf \
  --output estimates/<slug>/.source.md
```

For DOCX:

```bash
uv run --script resources/extract.py \
  --input /path/to/rfp.docx \
  --output estimates/<slug>/.source.md
```

For scanned PDFs (OCR fallback, requires tesseract installed system-wide):

```bash
uv run --script resources/extract.py \
  --input /path/to/scanned.pdf \
  --output estimates/<slug>/.source.md \
  --ocr
```

## What the script does (by input type)

| Input | Primary | Fallback | OCR |
|---|---|---|---|
| Text PDF | `pdfplumber` | `pdftotext -layout` | — |
| Scanned PDF | `pdfplumber` → empty → OCR | `pdftotext` | `tesseract -l ces` |
| DOCX | `python-docx` | — | — |
| TXT/MD | pass-through | — | — |

## Dependencies

All pinned inline in the script header (PEP 723 — `uv run --script`):

```python
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "pdfplumber>=0.11",
#   "python-docx>=1.1",
#   "pytesseract>=0.3.10",
#   "pdf2image>=1.17",
#   "Pillow>=10.0",
# ]
# ///
```

`uv` manages the environment automatically. First call may take ~30s to install.

For OCR you need `tesseract` + Czech language pack (`tesseract-ocr-ces`) and `poppler` (for `pdf2image`) installed system-wide:

```bash
brew install tesseract tesseract-lang poppler
```

## Post-processing checklist

After extraction, verify:
1. File exists and is > 500 chars (otherwise OCR may have failed)
2. Czech diacritics render correctly (test: look for `č`, `ř`, `ž`, `á`)
3. Page markers `## Page N` are present
4. Tables (if any) are preserved (check for `|` pipe characters)

If step 2 fails, re-run with `--ocr --normalize nfc`.

## Resources

- `resources/extract.py` — the extraction script
