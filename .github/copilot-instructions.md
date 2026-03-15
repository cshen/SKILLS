# Copilot Instructions

## Repository Overview

This is a monorepo of **Copilot CLI skills** — self-contained Python CLI tools, each in its own subdirectory. Each skill is designed to be invoked by the GitHub Copilot CLI agent to interact with external services on behalf of the user.

Current skills: `mail139` (139.com IMAP email), `dida365` (TickTick/Dida365 task manager).

## Skill Structure

Every skill directory contains exactly three files:

```
<skill-name>/
  SKILL.md      # Agent instructions + YAML front-matter (name, slug, version, description, metadata)
  README.md     # Human-facing documentation
  <script>.py   # Single-file Python CLI (pure stdlib preferred)
```

### SKILL.md format

SKILL.md has a YAML front-matter block followed by Markdown:

```yaml
---
name: <skill-name>
slug: <skill-name>
version: 1.0.0
description: <one-line description used for skill matching/triggering>
metadata: {"clawdbot":{"emoji":"<emoji>","requires":{"bins":["python3"]},"os":["linux","darwin","win32"]}}
---
```

The body must include:
- **Prerequisites** — env vars required; instruct the agent to stop and tell the user to set them if missing
- **Tool Location** — `{baseDir}/<script>.py` (use `{baseDir}` placeholder, not a hardcoded path)
- **When to Use This Skill** — trigger phrases and use cases
- **Commands Reference** — all commands with options table and examples using `{baseDir}` and env var refs
- **Behavioral Rules** — numbered list of strict agent rules (what to default to, what to never do, how to handle errors)

### Python script conventions

- **Pure Python stdlib only** — no `pip install` required at runtime; optional third-party packages (e.g. `html2text`) are caught with `try/except` and gracefully fall back
- Single-file scripts using `argparse` with subcommands
- Credentials sourced from env vars first, then CLI flags, then `getpass.getpass()` as last resort
- Errors print to `stderr` and `sys.exit(1)`; normal output to `stdout`
- Non-destructive by default (read-only operations); destructive side effects require explicit opt-in flags
- `{baseDir}` is a template placeholder in SKILL.md only — the actual script path is resolved at runtime by the skill system

## Running a Skill Script

```bash
# Direct invocation (replace {baseDir} with the actual skill directory)
python3 mail139/mail139.py -u "$MAIL139_ID" -p "$MAIL139_TOKEN" <command> [options]

# Or rely on env var defaults
MAIL139_ID=you@139.com MAIL139_TOKEN=secret python3 mail139/mail139.py fetch
```

No build step, no dependency installation needed (stdlib only).

## Adding a New Skill

1. Create `<skill-name>/` directory with `SKILL.md`, `README.md`, and `<script>.py`
2. Follow the SKILL.md front-matter schema exactly (copy from an existing skill)
3. Use `{baseDir}` in all SKILL.md command examples, never hardcode paths
4. Keep the Python script self-contained in a single file using only stdlib
5. Define clear behavioral rules in SKILL.md so the agent knows exactly when and how to use the skill

## Credential Conventions

| Skill | Env Var(s) |
|---|---|
| mail139 | `MAIL139_ID`, `MAIL139_TOKEN` (fallback: `MAIL139_PASSWORD`) |
| dida365 | `TICKTICK_TOKEN` |

Never echo credential values in output or explanations. If a required env var is missing, instruct the user to `export` it before proceeding.
