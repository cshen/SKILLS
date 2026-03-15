---
name: mail139
slug: mail139
version: 1.0.0
description: Read and send email via IMAP/SMTP. Check for new/unread messages, fetch content, search mailboxes, mark as read/unread, and send emails with attachments. Works with any IMAP/SMTP server including Gmail, Outlook, 163.com, vip.163.com, etc.
metadata: {"clawdbot":{"emoji":"📬","requires":{"bins":["python3"]},"os":["linux","darwin","win32"]}}
---

# mail139 — 139.com Email Downloader 📬

Download and search emails from [139.com](https://mail.139.com) via IMAP using pure Python stdlib. No pip installs needed.

## Prerequisites

- `MAIL139_ID` — 139.com email address (e.g. `you@139.com`)
- `MAIL139_TOKEN` — account password/token (fallbacks: prompt or `MAIL139_PASSWORD`)
- If either is missing, **stop and tell the user** to set them:
  ```bash
  export MAIL139_ID="you@139.com"
  export MAIL139_TOKEN="your-password"
  ```
- IMAP access must be enabled in the 139.com account settings (设置 → POP3/SMTP/IMAP)

## Tool Location

The CLI script is bundled with this skill:

```
{baseDir}/mail139.py
```

All commands follow the pattern:

```bash
python3 {baseDir}/mail139.py -u "$MAIL139_ID" -p "$MAIL139_TOKEN" <command> [options]
# or simply rely on env defaults:
MAIL139_ID=you@139.com MAIL139_TOKEN=secret python3 {baseDir}/mail139.py <command> [options]
```

## When to Use This Skill

Activate when the user wants to:
- Read, check, or view emails from their 139.com inbox
- Download or save emails to disk
- Search emails by keyword or date
- List mailbox folders on 139.com
- Export emails as JSON or `.eml` files
- Save email attachments from 139.com

**Trigger phrases:** "check my 139 email", "read my 139.com inbox", "download emails from 139", "search my 139 mail", "list my 139 folders", "save emails from 139.com", "139邮箱", "中国移动邮箱", "check inbox"

## Commands Reference

### List Folders

```bash
python3 {baseDir}/mail139.py -u "$MAIL139_ID" -p "$MAIL139_TOKEN" list-folders
```

Lists all IMAP mailboxes/folders on the account. Run this first if the user wants to fetch from a non-INBOX folder and you don't know the exact folder name.
Folder names are decoded from IMAP modified UTF-7 (handles Chinese names); copy the exact output when passing `--folder`.

### Fetch Emails

```bash
python3 {baseDir}/mail139.py -u "$MAIL139_ID" -p "$MAIL139_TOKEN" fetch [options]
```

| Option | Default | Description |
|---|---|---|
| `--folder <name>` | `INBOX` | IMAP folder to fetch from |
| `--limit <N>` | `10` | Max emails to fetch (newest first) |
| `--since <DD-Mon-YYYY>` | — | Only emails on or after this date |
| `--search <text>` | — | Filter by text in headers or body |
| `--format <fmt>` | `text` | Output format: `text`, `json`, or `eml` |
| `--output <dir>` / `-o <dir>` | — | Directory to save output files |
| `--save-attachments` | off | Save attachments (defaults to `~/Downloads` if `--output` is omitted) |
| `--mark-read` | off | Mark fetched emails as read on the server |

> For `--format eml`, files are written to `--output`. If `--output` is omitted, the existing `~/Downloads` directory is used. If `~/Downloads` does not exist, the command exits with an error.

> HTML bodies are converted to plain text via `html2text` (if installed), else `lynx --dump`, else an internal stripper. No HTML tags appear in printed/JSON bodies.

**Examples:**

```bash
# Print latest 10 emails to console
python3 {baseDir}/mail139.py -u "$MAIL139_ID" -p "$MAIL139_TOKEN" fetch

# Fetch last 20 emails as JSON
python3 {baseDir}/mail139.py -u "$MAIL139_ID" -p "$MAIL139_TOKEN" fetch \
  --limit 20 --format json

# Save as JSON to a directory
python3 {baseDir}/mail139.py -u "$MAIL139_ID" -p "$MAIL139_TOKEN" fetch \
  --format json -o ./emails

# Save raw .eml files and extract attachments
python3 {baseDir}/mail139.py -u "$MAIL139_ID" -p "$MAIL139_TOKEN" fetch \
  --format eml --save-attachments -o ./emails

# Fetch from Sent folder since a date
python3 {baseDir}/mail139.py -u "$MAIL139_ID" -p "$MAIL139_TOKEN" fetch \
  --folder "Sent Messages" --since "01-Jan-2025" --limit 50

# Search for emails containing a keyword
python3 {baseDir}/mail139.py -u "$MAIL139_ID" -p "$MAIL139_TOKEN" fetch \
  --search "invoice" --format json
```

## Output Format Details

### `text`
Prints each email to stdout with a header block (UID, Date, From, To, Subject, Attachments) and up to 2 000 characters of body text. Ideal for quick reading.

### `json`
Produces an array of objects. Each object has:
```json
{
  "uid": "1234",
  "date": "Mon, 10 Mar 2025 09:00:00 +0800",
  "from": "sender@example.com",
  "to": "you@139.com",
  "subject": "Hello",
  "content_type": "text/plain",
  "body": "Email body text…",
  "attachments": ["report.pdf"]
}
```
Written to `emails.json` inside `--output`, or printed to stdout if no `--output` is given.

### `eml`
Saves each email as `<uid>.eml` — a raw RFC 822 file openable in any email client. Requires `--output`.

## Important Details

### Date Format for `--since`
Use IMAP date format: `DD-Mon-YYYY` — e.g. `01-Jan-2025`, `15-Mar-2026`.

### Folder Names
139.com folder names may be in Chinese. Always run `list-folders` first if unsure. Common folders:
- `INBOX` — inbox (always English)
- `Sent Messages` — sent mail
- `Drafts` — drafts
- `Deleted Messages` — trash

### Attachment Saving
Attachments are saved to `<output>/<uid>_attachments/<filename>`. If `--output` is not set, attachments default to `~/Downloads/<uid>_attachments/`. The `--save-attachments` flag works independently of `--output`. By default attachments are saved to ~/Downloads if `--output` is not specified.

### Read-Only by Default
Without `--mark-read`, the script opens the mailbox read-only and leaves no server-side trace. Pass `--mark-read` only if the user explicitly asks to mark emails as read.

## Behavioral Rules

1. **Always use `python3`** to invoke the script.
2. **Prefer env vars for credentials** (`$MAIL139_ID`, `$MAIL139_TOKEN` fallback `$MAIL139_PASSWORD`) — never echo passwords in plain text in explanations.
3. **If `MAIL139_ID` or `MAIL139_TOKEN` are not set**, stop and ask the user to export them before proceeding (or be ready to prompt for password).
4. **Default to `--format text`** for casual "check my email" requests; use `json` when the user wants to process or save data; use `eml` when they want to archive or open in an email client.
5. **When the user asks to search**, use `--search` for keyword filters and `--since` for date filters; combine both when appropriate.
6. **When the user asks for a specific folder**, run `list-folders` first if you are unsure of the exact folder name.
7. **Do not use `--mark-read`** unless the user explicitly asks to mark emails as read.
8. **After fetching JSON**, parse and summarise the results for the user — don't just dump the raw JSON unless asked.
9. **If a command fails**, read stderr and explain the issue in plain language (e.g. wrong password, IMAP not enabled, network error).
10. **For attachment tasks**, `--save-attachments` works without `--output` — attachments will be saved to `~/Downloads/<uid>_attachments/` by default. Only set `--output` if the user wants a specific location.
