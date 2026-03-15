# mail139

A minimal Python CLI to download emails from [139.com](https://mail.139.com) via IMAP, built entirely on the Python standard library — no third-party packages required. Designed for simplicity, security, and ease of use, `mail139` allows you to fetch emails, save attachments, and export in multiple formats with just a few commands.
Need to install Python library html2text `pip3 install html2text` or lynx `brew install lynx` for macOS, to get better text output for HTML emails, otherwise it will fall back to a basic tag stripper which may not render complex HTML well.


## Features

- **Zero dependencies** — uses only Python stdlib (`imaplib`, `email`, `ssl`, `argparse`, `json`)
- **Three output formats** — pretty-printed text, JSON, or raw `.eml` files
- **Attachment saving** — extract and save attachments to disk
- **Filtering** — filter by date (`--since`) or keyword (`--search`)
- **Non-destructive by default** — opens mailbox read-only; use `--mark-read` to opt in to side effects
- **Secure** — TLS/SSL enforced via `ssl.create_default_context()`

## Requirements

- Python 3.9+
- A 139.com account with IMAP access enabled

> [!NOTE]
> IMAP access may need to be enabled in your 139.com account settings before connecting.

> [!IMPORTANT]
> Some 139.com endpoints only support older TLS settings. If Python 3.12+ fails with `SSLV3_ALERT_HANDSHAKE_FAILURE`, `mail139` automatically retries with a legacy TLS 1.0 / security-level-1 context to restore compatibility.

## Usage

```
python3 mail139.py -u <email> [-p <password>] COMMAND [options]
```

If `-u`/`-p` are omitted, the tool falls back to:
- `MAIL139_ID` for the username
- `MAIL139_TOKEN` (or `MAIL139_PASSWORD`) for the password

If no password is available, the script prompts securely.

### Commands

#### `list-folders`

List all available IMAP folders/mailboxes on the account.

```bash
python3 mail139.py -u you@139.com list-folders
```

Folder names are decoded from IMAP modified UTF-7 (covers Chinese names). If you’re unsure of the exact folder name, run this first and copy the exact output.

#### `fetch`

Fetch emails from a folder and display or save them.

```bash
python3 mail139.py -u you@139.com fetch [options]
```

| Option | Default | Description |
|---|---|---|
| `--folder` | `INBOX` | IMAP folder to fetch from |
| `--limit N` | `10` | Maximum number of emails to fetch (newest first) |
| `--since DD-Mon-YYYY` | — | Only fetch emails on or after this date |
| `--search TEXT` | — | Filter by text in headers or body |
| `--format` | `text` | Output format: `text`, `json`, or `eml` |
| `--output DIR` / `-o DIR` | — | Directory to save output files |
| `--save-attachments` | off | Save attachments into subdirectories under `--output` (defaults to `~/Downloads` if omitted) |
| `--mark-read` | off | Mark fetched emails as read |

> [!NOTE]
> For `--format eml`, files are written to `--output`. If `--output` is omitted, the existing `~/Downloads` directory is used. If `~/Downloads` does not exist, the command exits with an error.

> [!TIP]
> HTML emails are rendered to plain text using `html2text` if installed, otherwise `lynx --dump`, otherwise an internal tag stripper. Printed/JSON bodies contain no HTML tags.

### Examples

```bash
# Print the 10 most recent emails to the console
python3 mail139.py -u you@139.com fetch

# Save emails as JSON
python3 mail139.py -u you@139.com fetch --format json -o ./output

# Save raw .eml files and their attachments
python3 mail139.py -u you@139.com fetch --format eml --save-attachments -o ./emails

# Fetch up to 50 emails from a specific folder since a date
python3 mail139.py -u you@139.com fetch --folder "Sent Messages" --limit 50 --since "01-Jan-2025"

# Search for emails containing a keyword
python3 mail139.py -u you@139.com fetch --search "invoice" --format json

# Use environment variables for credentials
MAIL139_ID=you@139.com MAIL139_TOKEN=secret python3 mail139.py fetch
```

## Server Settings

| | |
|---|---|
| **IMAP host** | `imap.139.com` |
| **IMAP port** | `993` |
| **Security** | SSL/TLS |

## Output Formats

**`text`** — Prints each email to the console with a structured header block and up to 2 000 characters of body text.

**`json`** — Writes a `emails.json` file (or prints to stdout if `--output` is not set) containing an array of objects with fields: `uid`, `date`, `from`, `to`, `subject`, `content_type`, `body`, `attachments`.

**`eml`** — Saves each email as a raw `<uid>.eml` file that can be opened in any email client.
