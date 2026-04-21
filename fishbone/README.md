# fishbone

A Fish shell library of common utility functions for reuse when writing Fish scripts.

## Usage

Source the library at the top of your script:

```fish
source skeleton.fish
```

Then call `script:initialize` to set up the environment (colors, terminal detection, OS info, log/tmp dirs):

```fish
set LOG_DIR /tmp/myapp/log
set TMP_DIR /tmp/myapp/tmp
script:initialize
```

## Global variables (set before sourcing or after `script:initialize`)

| Variable   | Default | Description |
|------------|---------|-------------|
| `VERBOSE`  | `1`     | Set to `0` to enable debug output |
| `QUIET`    | `1`     | Set to `0` to suppress normal output |
| `FORCE`    | `1`     | Set to `0` to auto-install missing packages without prompting |
| `LOG_DIR`  | *(unset)* | Directory for log files |
| `TMP_DIR`  | *(unset)* | Directory for temporary files |
| `log_file` | *(unset)* | Override log file path (auto-set by `script:initialize` when `LOG_DIR` is set) |

> **Convention:** `0` = enabled/true, `1` = disabled/false (Unix exit-code style)

---

## Function reference

### `io:` — Input / Output

| Function | Description |
|----------|-------------|
| `io:init` | Detect terminal, enable colors/unicode, set icon characters |
| `io:print <msg>` | Print message to stdout (respects `QUIET`) |
| `io:debug <msg>` | Print debug line to stderr (respects `VERBOSE`) |
| `io:alert <msg>` | Print warning to stderr with alert icon |
| `io:success <msg>` | Print success message with check icon |
| `io:announce <msg>` | Print notice with wait icon, then pause 1s |
| `io:die <msg>` | Print error and exit via `script:safe_exit` |
| `io:progress <msg>` | Overwrite current line with a progress message |
| `io:countdown <secs> <msg>` | Countdown timer with progress display |
| `io:confirm` | Prompt `[y/N]`; returns 0 on yes. Skips if `FORCE=0` |
| `io:ask <prompt> <default>` | Read a value with a default; returns the value |
| `io:log <msg>` | Append timestamped message to `$log_file` |

### `str:` — String utilities

| Function | Description |
|----------|-------------|
| `str:trim` | Trim leading/trailing whitespace (pipe or args) |
| `str:lower` | Convert to lowercase (pipe or args) |
| `str:upper` | Convert to uppercase (pipe or args) |
| `str:ascii` | Remove diacritics/accents (pipe) |
| `str:slugify <text> [sep]` | Slugify text; default separator `_` |
| `str:title <text> [sep]` | TitleCase text; default separator `_` |
| `str:md5 [length]` | MD5 hash of stdin, truncated to `length` chars (default 10) |
| `str:column <n> [delim]` | Extract column `n` from piped input |
| `str:row <n>` | Extract row `n` from piped input |

### `system:` — OS / filesystem

| Function | Description |
|----------|-------------|
| `system:tempfile [ext]` | Create a temp file path; registers for cleanup; default ext `txt` |
| `system:folder <dir> [days]` | Create dir if missing; delete files older than `days` (default 365) |
| `system:follow_link <path>` | Resolve symlinks to the real path |
| `system:load_env` | Load `.env` files from the script's install folder |
| `system:notify <msg> [title]` | Desktop notification (macOS/Linux) |
| `system:busy <pid> <msg>` | Show a spinner while process `pid` is running |
| `system:require <binary> [install-hint]` | Check binary exists; install or die if missing |

### `script:` — Script lifecycle

| Function | Description |
|----------|-------------|
| `script:initialize` | Full setup: `io:init` + `script:housekeeping` + `script:init` |
| `script:init` | Set up log file; clean old files from `LOG_DIR` / `TMP_DIR` |
| `script:housekeeping` | Detect script path, OS, shell, git repo, version |
| `script:meta` | Print script metadata summary (version, OS, shell, git, hash) |
| `script:safe_exit` | Remove temp files and exit cleanly |
| `script:check_version` | Check git remote for updates |
| `script:show_required <file>` | Print all `system:require` dependencies in `file` |

### `utility:` — Numeric helpers

| Function | Description |
|----------|-------------|
| `utility:time` | High-resolution epoch timestamp (float) |
| `utility:round <n> [decimals]` | Round a number to `decimals` places |
| `utility:throughput <start> [ops] [name]` | Print ops/sec or sec/op since `start` timestamp |

### `option:` — Option parsing

| Function | Description |
|----------|-------------|
| `option:filter <key>` | Filter option config by key (requires user-defined `option:config`) |

---

## Example script

```fish
#!/usr/bin/env fish
source /path/to/skeleton.fish

set LOG_DIR /tmp/myscript/log
set TMP_DIR /tmp/myscript/tmp
script:initialize

system:require jq
system:require curl

set tmpfile (system:tempfile json)
io:announce "Fetching data..."
curl -s https://api.example.com/data > $tmpfile

io:success "Done"
script:safe_exit
```

## The following is for human readers only, not part of the README; and agents should ignore the following

In 2024, human started this project but never finished. The purpose is to have a reusable library of common functions for Fish shell scripts, inspired by similar libraries in other languages. The goal is to provide a consistent set of utilities for input/output, string manipulation, system interactions, and script lifecycle management that can be easily sourced and used in any Fish script.
In 2026, Claude code completed this project. 
