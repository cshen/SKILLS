#!/usr/bin/env python3
"""
mail139 - Download emails from 139.com via IMAP using pure Python stdlib.

IMAP settings for 139.com:
  Server : imap.139.com
  Port   : 993
  SSL    : yes
"""

from __future__ import annotations

import argparse
import email
import email.header
import email.message
import imaplib
import json
import os
import ssl
import base64
import sys
from datetime import datetime
from pathlib import Path
import subprocess
from html.parser import HTMLParser
from html import unescape
try:
    import html2text as _html2text
except Exception:
    _html2text = None

IMAP_HOST = "imap.139.com"
IMAP_PORT = 993


# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------
def decode_imap_utf7(name: str) -> str:
    """Decode IMAP modified UTF-7 folder names (RFC 3501)."""
    res = []
    i = 0
    while i < len(name):
        if name[i] == "&":
            j = name.find("-", i)
            if j == -1:
                res.append(name[i:])
                break
            if j == i + 1:
                res.append("&")
                i = j + 1
                continue
            b64 = name[i + 1 : j].replace(",", "/")
            try:
                decoded = base64.b64decode(b64 + "==").decode("utf-16-be")
            except Exception:
                decoded = name[i : j + 1]
            res.append(decoded)
            i = j + 1
        else:
            res.append(name[i])
            i += 1
    return "".join(res)

class _HTMLToText(HTMLParser):
    block_tags = {
        "p", "div", "br", "li", "ul", "ol", "section", "header", "footer",
        "article", "h1", "h2", "h3", "h4", "h5", "h6", "table", "tr", "td",
        "thead", "tbody"
    }

    def __init__(self) -> None:
        super().__init__()
        self.chunks: list[str] = []
        self._ignore_stack: list[str] = []
        self._link_href: list[str] = []

    def handle_starttag(self, tag, attrs):
        if tag in ("script", "style"):
            self._ignore_stack.append(tag)
            return
        if tag in self.block_tags:
            self.chunks.append("\n")
        if tag == "li":
            self.chunks.append("- ")
        if tag == "a":
            href = dict(attrs).get("href")
            self._link_href.append(href or "")

    def handle_endtag(self, tag):
        if self._ignore_stack and self._ignore_stack[-1] == tag:
            self._ignore_stack.pop()
            return
        if tag in self.block_tags:
            self.chunks.append("\n")
        if tag == "a":
            href = self._link_href.pop() if self._link_href else ""
            if href:
                self.chunks.append(f" [{href}]")

    def handle_data(self, data):
        if self._ignore_stack:
            return
        if data:
            self.chunks.append(data)

    def handle_entityref(self, name):
        if self._ignore_stack:
            return
        self.chunks.append(unescape(f"&{name};"))

    def handle_charref(self, name):
        if self._ignore_stack:
            return
        try:
            cp = int(name[1:], 16) if name.lower().startswith("x") else int(name)
            self.chunks.append(chr(cp))
        except Exception:
            self.chunks.append(f"&#{name};")

    def text(self) -> str:
        raw = "".join(self.chunks)
        lines = [line.strip() for line in raw.splitlines()]
        # collapse consecutive empty lines
        out: list[str] = []
        prev_blank = False
        for ln in lines:
            if ln == "":
                if not prev_blank:
                    out.append("")
                prev_blank = True
            else:
                out.append(ln)
                prev_blank = False
        return "\n".join(out).strip()


def html_to_text(html_str: str) -> str:
    # 1) Prefer html2text if available (borrowed pattern from eml-to-md)
    if _html2text:
        try:
            conv = _html2text.HTML2Text()
            conv.body_width = 0
            conv.ignore_images = False
            conv.ignore_links = False
            conv.ignore_emphasis = False
            return conv.handle(html_str).strip()
        except Exception:
            pass

    # 2) Fallback to lynx --dump if installed
    try:
        proc = subprocess.run(
            ["lynx", "--dump", "--stdin"],
            input=html_str.encode("utf-8", errors="ignore"),
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            check=True,
        )
        return proc.stdout.decode("utf-8", errors="replace").strip()
    except Exception:
        # 3) Final fallback: lightweight internal stripper
        parser = _HTMLToText()
        parser.feed(html_str)
        parser.close()
        return parser.text()

def decode_header_value(raw: str) -> str:
    """Decode an RFC-2047-encoded header value to a plain string."""
    parts = email.header.decode_header(raw)
    decoded = []
    for chunk, charset in parts:
        if isinstance(chunk, bytes):
            decoded.append(chunk.decode(charset or "utf-8", errors="replace"))
        else:
            decoded.append(chunk)
    return "".join(decoded)


def get_body(msg: email.message.Message) -> tuple[str, str]:
    """Return (content_type, body_text) preferring plain text over html."""
    if msg.is_multipart():
        plain = html = ""
        for part in msg.walk():
            ct = part.get_content_type()
            cd = str(part.get("Content-Disposition", ""))
            if "attachment" in cd:
                continue
            charset = part.get_content_charset() or "utf-8"
            if ct == "text/plain" and not plain:
                plain = part.get_payload(decode=True).decode(charset, errors="replace")
            elif ct == "text/html" and not html:
                html = part.get_payload(decode=True).decode(charset, errors="replace")
        if plain:
            return "text/plain", plain
        return "text/plain", html_to_text(html)
    else:
        ct = msg.get_content_type()
        charset = msg.get_content_charset() or "utf-8"
        body = msg.get_payload(decode=True) or b""
        text = body.decode(charset, errors="replace")
        if ct == "text/html":
            return "text/plain", html_to_text(text)
        return ct, text


def list_attachments(msg: email.message.Message) -> list[str]:
    names = []
    for part in msg.walk():
        cd = str(part.get("Content-Disposition", ""))
        if "attachment" in cd:
            fn = part.get_filename()
            if fn:
                names.append(decode_header_value(fn))
    return names


def save_attachment(msg: email.message.Message, output_dir: Path) -> list[str]:
    saved = []
    for part in msg.walk():
        cd = str(part.get("Content-Disposition", ""))
        if "attachment" in cd:
            fn = part.get_filename()
            if fn:
                fn = decode_header_value(fn)
                dest = output_dir / fn
                dest.write_bytes(part.get_payload(decode=True))
                saved.append(str(dest))
    return saved


def msg_to_dict(uid: str, msg: email.message.Message) -> dict:
    ct, body = get_body(msg)
    return {
        "uid": uid,
        "date": msg.get("Date", ""),
        "from": decode_header_value(msg.get("From", "")),
        "to": decode_header_value(msg.get("To", "")),
        "subject": decode_header_value(msg.get("Subject", "")),
        "content_type": ct,
        "body": body,
        "attachments": list_attachments(msg),
    }


# ---------------------------------------------------------------------------
# IMAP connection
# ---------------------------------------------------------------------------

def connect(user: str, password: str) -> imaplib.IMAP4_SSL:
    ctx = ssl.create_default_context()
    conn = imaplib.IMAP4_SSL(IMAP_HOST, IMAP_PORT, ssl_context=ctx)
    conn.login(user, password)
    return conn


# ---------------------------------------------------------------------------
# commands
# ---------------------------------------------------------------------------

def cmd_list_folders(conn: imaplib.IMAP4_SSL) -> None:
    status, folders = conn.list()
    if status != "OK":
        print("ERROR: could not list folders", file=sys.stderr)
        return
    if not folders:
        print("No folders returned by server.")
        return
    for f in folders:
        # IMAP LIST response example (bytes):
        # b'(\\HasNoChildren) "/" "&g0l6P3ux-"'
        if isinstance(f, bytes):
            parts = f.split(b' "/" ')
            raw_name_bytes = parts[-1].strip() if parts else f.strip()
            if raw_name_bytes.startswith(b'"') and raw_name_bytes.endswith(b'"'):
                raw_name_bytes = raw_name_bytes[1:-1]
            raw_name = raw_name_bytes.decode("ascii", errors="replace")
        else:
            parts = f.split(' "/" ')
            raw_name = (parts[-1].strip() if parts else f.strip()).strip('"')
        # Folder names are in modified UTF-7 per RFC 3501.
        name = decode_imap_utf7(raw_name)
        print(name)


def cmd_fetch(
    conn: imaplib.IMAP4_SSL,
    folder: str,
    limit: int,
    since: str | None,
    search: str | None,
    output_dir: Path | None,
    fmt: str,
    save_attachments: bool,
    mark_read: bool,
) -> None:
    if fmt == "eml" and output_dir is None:
        eml_default = Path.home() / "Downloads"
        if not eml_default.exists():
            print(f"ERROR: --format eml requires existing directory {eml_default}. Create it or pass --output.", file=sys.stderr)
            sys.exit(1)
        output_dir = eml_default

    status, _ = conn.select(f'"{folder}"', readonly=not mark_read)
    if status != "OK":
        print(f"ERROR: cannot open folder '{folder}'", file=sys.stderr)
        sys.exit(1)

    # build search criteria
    criteria_parts = []
    if not mark_read:
        criteria_parts.append("ALL")
    if since:
        criteria_parts.append(f'SINCE "{since}"')
    if search:
        criteria_parts.append(f'TEXT "{search}"')
    criteria = " ".join(criteria_parts) if criteria_parts else "ALL"

    status, data = conn.uid("search", None, criteria)
    if status != "OK":
        print("ERROR: search failed", file=sys.stderr)
        sys.exit(1)

    uids = data[0].split()
    if not uids:
        print("No messages found.")
        return

    # newest first, apply limit
    uids = list(reversed(uids))[:limit]
    print(f"Fetching {len(uids)} message(s) from '{folder}'…\n")

    if output_dir:
        output_dir.mkdir(parents=True, exist_ok=True)

    results = []
    for uid in uids:
        uid_str = uid.decode()
        status, raw = conn.uid("fetch", uid, "(RFC822)")
        if status != "OK" or not raw or raw[0] is None:
            print(f"  [uid {uid_str}] fetch failed, skipping")
            continue

        raw_email = raw[0][1]
        msg = email.message_from_bytes(raw_email)
        info = msg_to_dict(uid_str, msg)

        if fmt == "json":
            results.append(info)
        elif fmt == "text":
            _print_email_text(info)
        elif fmt == "eml":
            _save_eml(uid_str, raw_email, output_dir or Path("."))

        if save_attachments:
            att_base = output_dir or Path.home() / "Downloads"
            att_dir = att_base / f"uid_{uid_str}_attachments"
            saved = save_attachment(msg, att_dir)
            if saved:
                print(f"  [uid {uid_str}] saved attachments: {saved}")

    if fmt == "json":
        payload = json.dumps(results, ensure_ascii=False, indent=2)
        if output_dir:
            dest = output_dir / "emails.json"
            dest.write_text(payload, encoding="utf-8")
            print(f"Saved to {dest}")
        else:
            print(payload)


def _print_email_text(info: dict) -> None:
    print("=" * 60)
    print(f"UID     : {info['uid']}")
    print(f"Date    : {info['date']}")
    print(f"From    : {info['from']}")
    print(f"To      : {info['to']}")
    print(f"Subject : {info['subject']}")
    if info["attachments"]:
        print(f"Attach  : {', '.join(info['attachments'])}")
    print("-" * 60)
    max_body = 20000
    print(info["body"][:max_body])
    if len(info["body"]) > max_body:
        print("… (truncated)")
    print()


def _save_eml(uid: str, raw: bytes, output_dir: Path) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    dest = output_dir / f"{uid}.eml"
    dest.write_bytes(raw)
    print(f"  Saved {dest}")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def build_parser() -> tuple[argparse.ArgumentParser, dict[str, argparse.ArgumentParser]]:
    p = argparse.ArgumentParser(
        prog="mail139",
        description="Download emails from 139.com via IMAP (pure Python stdlib).",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    p.add_argument(
        "-u",
        "--user",
        help="139.com email address (or set MAIL139_ID)",
    )
    p.add_argument(
        "-p", "--password",
        default=None,
        help="Password (or set MAIL139_TOKEN / MAIL139_PASSWORD env vars)",
    )

    sub = p.add_subparsers(dest="command", metavar="COMMAND")

    subcommands: dict[str, argparse.ArgumentParser] = {}

    # list-folders
    list_p = sub.add_parser("list-folders", help="List all IMAP folders/mailboxes")
    subcommands["list-folders"] = list_p

    # fetch
    f = sub.add_parser("fetch", help="Fetch and display/save emails")
    subcommands["fetch"] = f
    f.add_argument("--folder", default="INBOX", help="IMAP folder to fetch from")
    f.add_argument("--limit", type=int, default=10, help="Max number of emails to fetch")
    f.add_argument(
        "--since",
        metavar="DD-Mon-YYYY",
        help='Fetch emails since date, e.g. "01-Jan-2025"',
    )
    f.add_argument("--search", metavar="TEXT", help="Search for text in email body/headers")
    f.add_argument(
        "--output", "-o",
        metavar="DIR",
        help="Directory to save output files",
    )
    f.add_argument(
        "--format",
        choices=["text", "json", "eml"],
        default="text",
        help="Output format: text (console), json, or raw .eml files",
    )
    f.add_argument(
        "--save-attachments",
        action="store_true",
        help="Save attachments (defaults to ~/Downloads if --output is omitted)",
    )
    f.add_argument(
        "--mark-read",
        action="store_true",
        help="Mark fetched emails as read (default: read-only, no side effects)",
    )

    return p, subcommands


def main() -> None:
    parser, subcommands = build_parser()
    args = parser.parse_args()

    user = args.user or os.environ.get("MAIL139_ID")
    password = args.password or os.environ.get("MAIL139_TOKEN") or os.environ.get("MAIL139_PASSWORD")

    if not args.command:
        parser.print_help()
        print("\nSubcommands:\n")
        for name, sp in subcommands.items():
            print(f"[{name}]\n")
            sp.print_help()
            print()
        sys.exit(0)

    if not user:
        print("ERROR: Provide --user or set MAIL139_ID", file=sys.stderr)
        sys.exit(1)

    if not password:
        import getpass
        password = getpass.getpass(f"Password for {user}: ")

    print(f"Connecting to {IMAP_HOST}:{IMAP_PORT} …", file=sys.stderr)
    try:
        conn = connect(user, password)
    except imaplib.IMAP4.error as e:
        print(f"Login failed: {e}", file=sys.stderr)
        sys.exit(1)
    except OSError as e:
        print(f"Connection error: {e}", file=sys.stderr)
        sys.exit(1)

    try:
        if args.command == "list-folders":
            cmd_list_folders(conn)

        elif args.command == "fetch":
            output_dir = Path(args.output) if args.output else None
            cmd_fetch(
                conn,
                folder=args.folder,
                limit=args.limit,
                since=args.since,
                search=args.search,
                output_dir=output_dir,
                fmt=args.format,
                save_attachments=args.save_attachments,
                mark_read=args.mark_read,
            )
    finally:
        conn.logout()


if __name__ == "__main__":
    main()
