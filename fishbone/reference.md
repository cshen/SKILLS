# Fishbone reference for agents

This file is the **agent-facing calling guide** for `skeleton.fish`. It explains **when to use each function**, **what it expects**, and **how to call it safely** from a Fish script.

## Standard setup

Most scripts should use this pattern:

```fish
#!/usr/bin/env fish

source /path/to/skeleton.fish

set LOG_DIR /tmp/my-agent/log
set TMP_DIR /tmp/my-agent/tmp
script:initialize
system:load_env

# ...your script logic...

script:safe_exit
```

## Agent usage rules

1. **Prefer `script:initialize`** over calling `io:init`, `script:housekeeping`, and `script:init` separately.
2. **Capture stdout** from functions that return values:
   ```fish
   set tmpfile (system:tempfile json)
   set answer (io:ask "Project name" demo)
   ```
3. **Pipeline helpers expect stdin** when noted:
   ```fish
   echo " Hello " | str:trim
   ```
4. **Boolean-style globals use shell exit-code semantics**:
   - `0` = enabled / true
   - `1` = disabled / false
5. **Interactive helpers**:
   - `io:confirm` auto-returns yes when `FORCE=0`
   - `system:require` auto-installs when `FORCE=0`
6. **Termination helpers**:
   - `io:die` stops the script through `script:safe_exit`
   - `script:safe_exit` removes registered temp files and exits cleanly
7. **Safe cleanup rule**: `system:folder` only deletes old files in paths containing `log`, `temp`, or `tmp`.

---

## `io:` functions

### `io:init`

**Use when:** you want low-level terminal and icon setup without the rest of script initialization. In most cases, use `script:initialize` instead.

```fish
source /path/to/skeleton.fish
io:init
io:print "Terminal helpers are ready"
```

### `io:print <message>`

**Use when:** you want normal stdout output that respects `QUIET`.

```fish
io:print "Processing $filename"
```

### `io:debug <message>`

**Use when:** you want debug output on stderr. It is shown only when `VERBOSE=0`.

```fish
set VERBOSE 0
io:debug "Current target folder: $TMP_DIR"
```

### `io:alert <message>`

**Use when:** you need a warning on stderr but the script should continue.

```fish
if test ! -f "$config_file"
    io:alert "Config file missing, using defaults"
end
```

### `io:success <message>`

**Use when:** you want to report a successful step in a user-friendly way.

```fish
io:success "Backup completed"
```

### `io:announce <message>`

**Use when:** you want a visible "about to do work" message before a slow step. This prints a notice and pauses for one second.

```fish
io:announce "Fetching remote metadata"
curl -s https://example.com/data.json >/dev/null
```

### `io:progress <message>`

**Use when:** you want a single-line progress update while a loop or task is running.

```fish
for i in (seq 1 10)
    io:progress "Processed $i of 10 files"
    sleep 0.2
end
io:print ""
```

### `io:countdown <seconds> <message>`

**Use when:** you want a short visible countdown before an irreversible action.

```fish
io:countdown 5 "Deleting temp files in"
```

### `io:confirm`

**Use when:** you need a yes/no confirmation from the user. Returns status `0` for yes and `1` for no. If `FORCE=0`, it skips the prompt and returns yes.

```fish
if io:confirm
    rm -rf /tmp/my-agent/tmp/*
end
```

### `io:ask <prompt> <default>`

**Use when:** you need a free-form value from the user and want a default fallback. The function prints the chosen value to stdout.

```fish
set project_name (io:ask "Project name" my-app)
io:print "Using project: $project_name"
```

### `io:log <message>`

**Use when:** you want to append a timestamped line to `$log_file`. This is a no-op unless `script:init` or `script:initialize` has set `log_file`.

```fish
set LOG_DIR /tmp/my-agent/log
script:initialize
io:log "Started sync run"
```

### `io:die <message>`

**Use when:** the script must stop immediately with cleanup.

```fish
if test ! -f "$input_file"
    io:die "Input file not found: $input_file"
end
```

---

## `str:` functions

### `str:trim`

**Use when:** you want to remove leading and trailing whitespace from an argument or piped input.

```fish
echo "  hello world  " | str:trim
str:trim "  hello world  "
```

### `str:lower`

**Use when:** you want lowercase text from an argument or piped input.

```fish
str:lower "Release Candidate"
echo "Release Candidate" | str:lower
```

### `str:upper`

**Use when:** you want uppercase text from an argument or piped input.

```fish
str:upper "deploy now"
echo "deploy now" | str:upper
```

### `str:ascii`

**Use when:** you need to strip accents and diacritics from piped text.

```fish
echo "crème brûlee" | str:ascii
```

### `str:slugify <text> [separator]`

**Use when:** you need a lowercase, URL-safe slug. The default separator is `_`.

```fish
str:slugify "Jack, Jill & Clémence LTD"
str:slugify "Jack, Jill & Clémence LTD" "-"
```

### `str:title <text> [separator]`

**Use when:** you need a compact TitleCase-style identifier. The default separator is `_`.

```fish
str:title "Jack, Jill & Clémence LTD"
str:title "Jack, Jill & Clémence LTD" "_"
```

### `str:md5 [length]`

**Use when:** you need an MD5 digest of piped input. The default output length is `10`.

```fish
echo "hello" | str:md5
echo "hello" | str:md5 8
```

### `str:column <n> [delimiter]`

**Use when:** you want column `n` from piped text. The default delimiter is a space.

```fish
echo "alpha beta gamma" | str:column 2
echo "alpha,beta,gamma" | str:column 2 ","
```

### `str:row <n>`

**Use when:** you want row `n` from piped text.

```fish
printf "first\nsecond\nthird\n" | str:row 2
```

---

## `utility:` functions

### `utility:round <number> [decimals]`

**Use when:** you need decimal rounding for numeric output.

```fish
utility:round 3.14159 2
```

### `utility:time`

**Use when:** you need a high-resolution timestamp for measuring work duration.

```fish
set t0 (utility:time)
sleep 1
set t1 (utility:time)
io:print "$t0 -> $t1"
```

### `utility:throughput <start> [operations] [name]`

**Use when:** you want a human-readable ops/sec or sec/op summary since a timestamp from `utility:time`.

```fish
set t0 (utility:time)
for i in (seq 1 100)
    sleep 0.01
end
utility:throughput $t0 100 files
```

---

## `system:` functions

### `system:tempfile [ext]`

**Use when:** you need a unique temp file path that will be cleaned up automatically by `script:safe_exit`.

```fish
set tmpfile (system:tempfile json)
echo '{"ok":true}' > $tmpfile
```

### `system:folder <dir> [days]`

**Use when:** you need to create a temp/log folder and clean out old files. The path must include `log`, `temp`, or `tmp`.

```fish
system:folder /tmp/my-agent/tmp 7
system:folder /tmp/my-agent/log 30
```

### `system:follow_link <path>`

**Use when:** you want the real target path for a symlink.

```fish
set real_path (system:follow_link ./current-release)
io:print $real_path
```

### `system:load_env`

**Use when:** you want to source `.env`, `.<script>.env`, and `<script>.env` from the script folder and current directory.

```fish
script:initialize
system:load_env
io:print "API_BASE is $API_BASE"
```

### `system:notify <message> [title]`

**Use when:** you want a desktop notification on macOS or Linux.

```fish
system:notify "Backup completed" "nightly-sync"
```

### `system:busy <pid> <message>`

**Use when:** you already launched a background process and want a spinner until it exits.

```fish
sleep 5 &
set pid $last_pid
system:busy $pid "Waiting for background job"
```

### `system:require <binary> [install-hint]`

**Use when:** a script depends on an external binary. If missing, it either auto-installs (`FORCE=0`) or exits with installation instructions.

```fish
system:require jq
system:require convert "brew install imagemagick"
```

---

## `script:` functions

### `script:initialize`

**Use when:** you want the normal one-line startup path. This is the preferred entry point for most scripts.

```fish
set LOG_DIR /tmp/my-agent/log
set TMP_DIR /tmp/my-agent/tmp
script:initialize
```

### `script:init`

**Use when:** `io:init` and `script:housekeeping` already ran and you only want log/tmp folder setup.

```fish
io:init
script:housekeeping
set LOG_DIR /tmp/my-agent/log
set TMP_DIR /tmp/my-agent/tmp
script:init
```

### `script:housekeeping`

**Use when:** you need script metadata such as OS, shell, install path, git info, or detected package manager.

```fish
io:init
script:housekeeping
io:print "Running on $os_name with $shell_brand"
```

### `script:meta`

**Use when:** you want a compact runtime summary for debugging or support output.

```fish
script:initialize
script:meta
```

### `script:safe_exit`

**Use when:** the script is done and should clean up all temp files created through `system:tempfile`.

```fish
set tmpfile (system:tempfile txt)
echo "done" > $tmpfile
script:safe_exit
```

### `script:check_version`

**Use when:** the script lives in a git repo and you want to warn about upstream updates.

```fish
script:initialize
script:check_version
```

### `script:show_required <file>`

**Use when:** you want to scan a Fish script for `system:require` calls and print one install command for all dependencies.

```fish
script:initialize
script:show_required ./deploy.fish
```

---

## `option:` functions

### `option:filter <key>`

**Use when:** your script defines `option:config` and you want to pull matching option values from that config. This is an internal helper for option parsing.

```fish
function option:config
    printf '%s\n' \
        'verbose|v|--verbose' \
        'quiet|q|--quiet' \
        'force|f|--force'
end

option:filter verbose
```

---

## Common agent patterns

### Minimal non-interactive script

```fish
source /path/to/skeleton.fish

set FORCE 0
set QUIET 1
set VERBOSE 1
set LOG_DIR /tmp/example/log
set TMP_DIR /tmp/example/tmp

script:initialize
system:require jq
system:load_env

set tmpfile (system:tempfile json)
io:announce "Downloading data"
curl -s "$API_BASE/items" > $tmpfile

io:success "Saved response to $tmpfile"
script:safe_exit
```

### Data cleanup pipeline

```fish
set slug (str:slugify (echo "  Clémence Release Candidate  " | str:trim) "-")
io:print $slug
```

### Timed workload

```fish
set t0 (utility:time)

for i in (seq 1 50)
    io:progress "Handled $i of 50 jobs"
    sleep 0.02
end

io:print ""
utility:throughput $t0 50 jobs
```
