# Skills

A collection of GitHub Copilot CLI skills.

## Installing a Skill

### Option 1 — From GitHub (recommended)

Use `npx skills` to install directly from this repo without cloning:

```bash
npx skills add https://github.com/cshen/SKILLS --skill mail139
npx skills add https://github.com/cshen/SKILLS --skill dida365
npx skills add https://github.com/cshen/SKILLS --skill xiaomi
npx skills add https://github.com/cshen/SKILLS --skill arXiv
npx skills add ... # and so on for each skill
```

### Option 2 — From a local clone

Clone the repo, then inside the Copilot CLI run `/skills add` with a path relative to where you cloned it:

```
/skills add ./mail139
/skills add ./dida365
/skills add ./xiaomi
/skills add ./arXiv
/skills add ./fishbone
/skills add ./mywiki
/skills add ./youtube_download
```

To verify installation: `/skills list`

---

## Available Skills

### 📬 mail139
Read, send, delete, reply, and forward email via IMAP/SMTP. Works with 139.com and any standard IMAP/SMTP server (Gmail, Outlook, etc.).

**Requires:** `python3`, env vars `MAIL139_ID` and `MAIL139_TOKEN`

```bash
npx skills add https://github.com/cshen/SKILLS --skill mail139
```

---

### ✅ dida365
Manage TickTick/Dida365 tasks and projects from the terminal — list, create, complete, update, and delete tasks via the Dida365 Open API.

**Requires:** `python3`, `curl`, env var `TICKTICK_TOKEN`

```bash
npx skills add https://github.com/cshen/SKILLS --skill dida365
```

---

### 🏠 xiaomi
Control Xiaomi Mijia smart home devices — list devices/scenes, get/set properties, run scenes, and issue natural language commands via Xiao Ai speaker.

**Requires:** `uvx`, first-time QR code login via the Mijia app

```bash
npx skills add https://github.com/cshen/SKILLS --skill xiaomi
```

---

### 📄 arXiv
Download arXiv papers as PDF, show title/authors/abstract, and generate BibTeX entries by arXiv ID (e.g. `2405.14458`).

**Requires:** `uvx`

```bash
npx skills add https://github.com/cshen/SKILLS --skill arXiv
```

---

### 🦴 fishbone
Write efficient Fish shell scripts by reusing the `skeleton.fish` library. Provides utilities for I/O, string manipulation, file handling, and script lifecycle management.

**Requires:** `fish` shell

```bash
npx skills add https://github.com/cshen/SKILLS --skill fishbone
```

---

### 📚 mywiki
Build and maintain a personal knowledge wiki. Incrementally organize research, notes, and documentation in a persistent, interconnected Markdown knowledge base with cross-references.

**Requires:** `python3`

```bash
npx skills add https://github.com/cshen/SKILLS --skill mywiki
```

---

### 🎥 youtube_download
Download videos, audio, or subtitles from YouTube, Bilibili, and other sites using yt-dlp. Supports multiple formats and quality options with Chrome cookie authentication.

**Requires:** `uvx`

```bash
npx skills add https://github.com/cshen/SKILLS --skill youtube_download
```
