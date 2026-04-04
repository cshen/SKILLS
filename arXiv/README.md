# arXiv Skill 📄

A GitHub Copilot CLI skill for downloading arXiv papers, browsing metadata, and generating BibTeX entries — powered by [`axs`](https://github.com/cshen/arxiv_download) via `uvx`.

## Requirements

- [`uv`](https://github.com/astral-sh/uv) installed (`uvx` on PATH)
- No API keys needed — arXiv is public

## What It Does

| Command | Description |
|---|---|
| `axs show <id>` | Print title, authors, and abstract |
| `axs get -d <dir> <id>` | Download PDF to a directory |
| `axs bib <id>` | Generate a BibTeX entry |

## Example Usage

```bash
# Browse a paper
uvx --from ./arxiv_download --python 3.12 axs show 2405.14458

# Download a paper
uvx --from ./arxiv_download --python 3.12 axs get -d ~/Papers 1706.03762

# Get BibTeX
uvx --from ./arxiv_download --python 3.12 axs bib math/0211159
```

## Trigger Phrases

"download arxiv paper", "get arxiv pdf", "show arxiv abstract", "bibtex for arxiv", "cite arxiv paper", "fetch arxiv 2405.14458"

## Underlying Package

The `arxiv_download/` subdirectory contains the `arxiv-script` package (local fork with filename sanitisation). It is invoked via `uvx --from ./arxiv_download --python 3.12 axs`.
