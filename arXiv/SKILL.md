---
name: arxiv
slug: arxiv
version: 1.0.0
description: Download arXiv papers as PDF, show title/authors/abstract, and generate BibTeX entries for arXiv preprints by arXiv ID.
metadata: {"clawdbot":{"emoji":"📄","requires":{"bins":["uvx"]},"os":["linux","darwin","win32"]}}
---

# arxiv — arXiv Paper Downloader 📄

Download arXiv preprints as PDF, browse metadata, and generate BibTeX entries — powered by the `axs` CLI via `uvx`.

## Prerequisites

- `uvx` (from [uv](https://github.com/astral-sh/uv)) must be installed and on `PATH`
- No API keys or credentials required — arXiv is a public repository
- If `uvx` is missing, stop and tell the user to install it:
  ```bash
  curl -LsSf https://astral.sh/uv/install.sh | sh
  ```

## Tool Location

The underlying script is bundled with this skill at:

```
{baseDir}/arxiv_download/
```

All commands use the pattern:

```bash
uvx --from {baseDir}/arxiv_download --python 3.12 axs <command> [options]
```

## When to Use This Skill

Activate when the user wants to:
- Look up an arXiv paper by its arXiv ID (e.g. `2405.14458`, `math/0211159`)
- Download a paper PDF from arXiv
- Generate a BibTeX entry for an arXiv paper
- Show the abstract, title, or authors of an arXiv paper
- Add a BibTeX entry to a `.bib` file

**Trigger phrases:** "download arxiv paper", "get arxiv pdf", "show arxiv abstract", "bibtex for arxiv", "cite arxiv paper", "fetch arxiv", "arxiv 2405.14458", "download paper"

## Commands Reference

### Show Paper Details

```bash
uvx --from {baseDir}/arxiv_download --python 3.12 axs show [--full] <ax_id>
```

| Option | Description |
|---|---|
| `--full` / `-f` | Show all authors and arXiv subject in addition to title and abstract |
| `<ax_id>` | arXiv identifier, e.g. `2405.14458` or `math/0211159` |

```bash
# Short summary (title, authors, abstract)
uvx --from {baseDir}/arxiv_download --python 3.12 axs show 2405.14458

# Full details including all authors and subject
uvx --from {baseDir}/arxiv_download --python 3.12 axs show --full math/0211159
```

### Download Paper PDF

```bash
uvx --from {baseDir}/arxiv_download --python 3.12 axs get [-d <directory>] [-o] <ax_id>
```

| Option | Default | Description |
|---|---|---|
| `-d` / `--directory` | `$DEFAULT_DIRECTORY` or required | Directory to save the PDF |
| `-o` / `--open-file` | off | Open the PDF after downloading |
| `<ax_id>` | required | arXiv identifier |

Saved filename format: `AUTHOR(S)-TITLE-YEAR.pdf` (title truncated to 15 words; 3+ authors use "et al").

```bash
# Download to ~/Papers/
uvx --from {baseDir}/arxiv_download --python 3.12 axs get -d ~/Papers 2405.14458

# Download and open immediately
uvx --from {baseDir}/arxiv_download --python 3.12 axs get -d ~/Papers -o 1706.03762
```

### Generate BibTeX Entry

```bash
uvx --from {baseDir}/arxiv_download --python 3.12 axs bib [-a <bib_file>] <ax_id>
```

| Option | Default | Description |
|---|---|---|
| `-a` / `--add-to` | — | Path to a `.bib` file to append the entry to |
| `<ax_id>` | required | arXiv identifier |

BibTeX key format: `AUTHOR(S)-SHORT_TITLE-AX_ID`

```bash
# Print BibTeX entry to stdout
uvx --from {baseDir}/arxiv_download --python 3.12 axs bib 2405.14458

# Append to a bib file (will prompt for confirmation)
uvx --from {baseDir}/arxiv_download --python 3.12 axs bib -a ~/thesis/refs.bib 2405.14458
```

### Set Persistent Defaults (optional)

```bash
# Set a default download directory (stored in .env)
uvx --from {baseDir}/arxiv_download --python 3.12 axs --set-directory ~/Papers

# Set a default bib file (stored in .env)
uvx --from {baseDir}/arxiv_download --python 3.12 axs --set-bib-file ~/thesis/refs.bib
```

## Behavioral Rules

1. **Always use `uvx --from {baseDir}/arxiv_download --python 3.12 axs`** — never invoke the script directly with `python3`.
2. **Replace `{baseDir}` with the actual skill directory path** at runtime.
3. **arXiv identifiers** can be modern (`2405.14458`) or legacy (`math/0211159`, `hep-th/0109187`) — pass them as-is.
4. **For `get`**, always supply `-d <directory>` unless the user has previously set a default via `--set-directory`. If no directory is available, ask the user where to save the file.
5. **For `bib`**, print the BibTeX entry to stdout by default. Only use `-a` when the user explicitly asks to add it to a `.bib` file.
6. **When appending to a `.bib` file** (`bib -a`), the tool will ask for confirmation interactively — run it in a terminal and let the user confirm.
7. **After `show`**, present the title, authors, and abstract clearly — do not just relay raw output verbatim.
8. **After `bib`**, display the BibTeX entry in a code block so the user can copy it easily.
9. **After `get`**, report the full saved path returned by the tool.
10. **If a command fails**, read stderr and explain the issue in plain language (e.g. invalid arXiv ID, network error, invalid directory path).
11. **Do not set defaults** (`--set-directory`, `--set-bib-file`) unless the user explicitly asks to change their default.
