# tt.py — TickTick / Dida365 CLI

A lightweight, **pure-Python** command-line client for [TickTick](https://ticktick.com) / [Dida365](https://dida365.com).
Zero external dependencies — only Python 3.6+ standard library.

---

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Usage](#usage)
  - [Projects](#projects)
  - [Tasks](#tasks)
  - [Add a Task](#add-a-task)
  - [Complete a Task](#complete-a-task)
  - [Update a Task](#update-a-task)
  - [Delete a Task](#delete-a-task)
  - [Add a Project](#add-a-project)
  - [Delete a Project](#delete-a-project)
- [Priority Levels](#priority-levels)
- [Project Resolution](#project-resolution)
- [Examples — Common Workflows](#examples--common-workflows)
- [Environment Variables](#environment-variables)
- [Error Handling](#error-handling)
- [License](#license)

---

## Features

| Capability | Command |
|---|---|
| List all projects | `projects` |
| List pending tasks | `tasks` |
| Create a task | `add` |
| Mark a task complete | `complete` |
| Update a task | `update` |
| Delete a task | `delete` |
| Create a project | `add-project` |
| Delete a project | `delete-project` |

---

## Prerequisites

- **Python 3.6+** (uses f-strings; no third-party packages needed)
- A **TickTick / Dida365 API token** ([generate one here](https://developer.dida365.com/manage))
- Configured for **Asia/Shanghai (+08:00)** timezone by default (edit `TIMEZONE` / `TZ_OFFSET` in `tt.py` to change)

---

## Setup

### 1. Clone or copy

```bash
# Drop tt.py anywhere on your PATH, or just keep it in a project folder
chmod +x tt.py
```

### 2. Export your API token

```bash
export TICKTICK_TOKEN="your-api-token-here"
```

> **Tip:** Add the export to your `~/.bashrc`, `~/.zshrc`, or `.env` file so it persists across sessions.

### 3. Verify

```bash
python3 tt.py projects
```

You should see a list of your projects. If `TICKTICK_TOKEN` is not set, the tool exits immediately with:

```
ERROR: TICKTICK_TOKEN not set
```

---

## Usage

```
tt.py <command> [options]
```

### Projects

List every project in your account. Both `projects` and `project` (singular) work as aliases.

```bash
python3 tt.py projects
```

**Output:**

```
📁 3 projects
  6478a1b2c3d4e5f6a7b8c9d0  Work
  6478a1b2c3d4e5f6a7b8c9d1  Personal
  6478a1b2c3d4e5f6a7b8c9d2  Shopping
```

---

### Tasks

List pending (incomplete) tasks for a project. Defaults to the **inbox** if `--project` is omitted.

Both `tasks` and `task` (singular) work as aliases.

```bash
# Inbox tasks (default)
python3 tt.py tasks

# Tasks in a named project
python3 tt.py tasks --project Work

# Tasks by project ID
python3 tt.py task --project 6478a1b2c3d4e5f6a7b8c9d0
```

**Output:**

```
📋 4 pending tasks:

  ○ [HIGH]  — start 2026-03-15: Fix login bug

  ○ [MED]   — start 2026-03-18: Write unit tests

  ○ [LOW]   — start 2026-03-20: Update README

  ○       : Buy coffee beans
```

Tasks are sorted by **priority** (high → low) then **start date** (earliest first).

---

### Add a Task

```bash
python3 tt.py add "Buy groceries"
```

**All options:**

```bash
python3 tt.py add "Deploy v2.0" \
  --project Work \
  --priority high \
  --start 2026-03-20T18:00:00 \
  --notes "Run full regression suite first" \
  --tag "release,urgent"
```

**Output:**

```
✅ Created: Deploy v2.0  start 2026-03-20 [high priority]
   id: 6478a1b2c3d4e5f6a7b8c9ff
```

If `--start` is omitted, a warning is shown:

```
⚠️  No start date set. Use --start YYYY-MM-DDTHH:MM:SS to set one.
✅ Created: Buy groceries . . . No start date [none priority]
   id: 6478a1b2c3d4e5f6a7b8c9ff
```

| Option | Description | Default |
|---|---|---|
| `--project <name\|id>` | Target project | `inbox` |
| `--priority <level>` | `none`, `low`, `med`, `high` | `none` |
| `--start <datetime>` | ISO 8601 datetime (timezone offset `+08:00` appended automatically) | — |
| `--notes <text>` | Task description / body | — |
| `--tag <tags>` | Comma-separated tags | — |

---

### Complete a Task

```bash
# Complete a task in the inbox
python3 tt.py complete 6478a1b2c3d4e5f6a7b8c9ff

# Complete a task in a specific project
python3 tt.py complete 6478a1b2c3d4e5f6a7b8c9ff --project Work
```

**Output:**

```
✅ Task 6478a1b2c3d4e5f6a7b8c9ff marked complete
```

---

### Update a Task

Change the title, priority, or due date of an existing task.

```bash
python3 tt.py update 6478a1b2c3d4e5f6a7b8c9ff \
  --project Work \
  --title "Deploy v2.1" \
  --priority med \
  --start 2026-03-25T10:00:00
```

**Output:**

```
✅ Updated: Deploy v2.1
```

| Option | Description |
|---|---|
| `--project <name\|id>` | Project the task belongs to (default: inbox) |
| `--title <text>` | New title |
| `--priority <level>` | New priority |
| `--start <datetime>` | New start date |

---

### Delete a Task

```bash
python3 tt.py delete 6478a1b2c3d4e5f6a7b8c9ff --project Work
```

**Output:**

```
🗑️  Task 6478a1b2c3d4e5f6a7b8c9ff deleted
```

If `--project` is omitted, the inbox is assumed.

---

### Add a Project

```bash
# Default blue colour
python3 tt.py add-project "Side Projects"

# Custom colour
python3 tt.py add-project "Fitness" --color "#E24A4A"
```

**Output:**

```
✅ Project created: Side Projects (id: 6478a1b2c3d4e5f6a7b8c9e0)
```

---

### Delete a Project

```bash
python3 tt.py delete-project 6478a1b2c3d4e5f6a7b8c9e0
```

**Output:**

```
🗑️  Project 6478a1b2c3d4e5f6a7b8c9e0 deleted
```

---

## Priority Levels

| Flag value | API value | Display |
|---|---|---|
| `none` | 0 | *(blank)* |
| `low` | 1 | `[LOW]` |
| `med` / `medium` | 3 | `[MED]` |
| `high` | 5 | `[HIGH]` |

---

## Project Resolution

The `--project` option accepts any of the following:

| Input | Behaviour |
|---|---|
| `inbox` | Maps to the built-in inbox project |
| `Work` | Case-insensitive name lookup via the API |
| `6478a1b2c3d4e5f6a7b8c9d0` | 24-character hex ID — used as-is |

---

## Examples — Common Workflows

### Morning review

```bash
# See what's on your plate today
python3 tt.py tasks
python3 tt.py tasks --project Work
```

### Quick-add tasks throughout the day

```bash
python3 tt.py add "Reply to Alex's email" --priority med
python3 tt.py add "Book dentist appointment" --start 2026-03-14T09:00:00
python3 tt.py add "Review PR #42" --project Work --priority high --tag "code-review"
```

### End-of-day cleanup

```bash
# Mark finished items complete
python3 tt.py complete 6478a1b2c3d4e5f6a7b8c9f1
python3 tt.py complete 6478a1b2c3d4e5f6a7b8c9f2 --project Work

# Reschedule something you didn't get to
python3 tt.py update 6478a1b2c3d4e5f6a7b8c9f3 --start 2026-03-14T10:00:00

# Delete a task you no longer need
python3 tt.py delete 6478a1b2c3d4e5f6a7b8c9f4
```

### Organise with projects

```bash
# Create a new project for a trip
python3 tt.py add-project "Japan Trip" --color "#FF6B6B"

# Add tasks to it
python3 tt.py add "Book flights" --project "Japan Trip" --priority high --start 2026-04-01T12:00:00
python3 tt.py add "Reserve hotel" --project "Japan Trip" --start 2026-04-05T12:00:00
python3 tt.py add "Get travel insurance" --project "Japan Trip" --tag "admin,finance"

# Check progress
python3 tt.py tasks --project "Japan Trip"
```

### Shell alias (optional)

Add to your `~/.bashrc` or `~/.zshrc` for a shorter command:

```bash
alias tt='python3 /path/to/tt.py'
```

Then simply:

```bash
tt tasks
tt add "Something quick"
tt complete abc123def456abc123def456
```

---

## Environment Variables

| Variable | Required | Description |
|---|---|---|
| `TICKTICK_TOKEN` | **Yes** | Bearer token for the Dida365 / TickTick Open API |

---

## Error Handling

| Scenario | Behaviour |
|---|---|
| `TICKTICK_TOKEN` not set | Prints error to stderr, exits with code 1 |
| Unknown command | Prints usage to stderr, exits with code 1 |
| Unknown option | Prints error to stderr, exits with code 1 |
| Invalid priority value | Prints error to stderr, exits with code 1 |
| Project name not found | Prints error to stderr, exits with code 1 |
| API returns an error | Prints the API error message to stderr, exits with code 1 |
| Missing required argument | Prints error to stderr, exits with code 1 |

All errors go to **stderr** so they don't pollute piped output.

---

## License

MIT
