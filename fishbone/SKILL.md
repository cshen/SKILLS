# fishbone — Fish Script Writing Skill

> **For AI agents (Copilot, Claude Code, etc.)**  
> This skill teaches you to write efficient Fish shell scripts by reusing the
> `skeleton.fish` library from this repository. Read this file before writing
> any Fish script in a project that contains `skeleton.fish`.

---

## Decision: source the library or inline?

Apply this rule every time you write a Fish script:

| Condition | Action |
|-----------|--------|
| Script uses **3 or more** library functions | `source /path/to/skeleton.fish` and call them directly |
| Script uses **lifecycle functions** (`script:initialize`, `script:safe_exit`, `io:die`) | Always source — these depend on internal state |
| Script uses **only 1–2 simple, stateless helpers** (`str:trim`, `str:lower`, `str:column`, `str:row`, `str:md5`, `utility:round`) | Inline a minimal adapted version **without** sourcing |
| Script is a one-liner or short pipeline | Inline or use native Fish builtins |

### Inline-safe functions (stateless, no library deps)

These can be copied verbatim or lightly adapted when sourcing the whole library is
overkill.  Copy only the functions you actually need.

```fish
# str:trim — remove leading/trailing whitespace
function str:trim
    if test (count $argv) -gt 0
        printf '%s' $argv | string trim
    else
        string trim
    end
end

# str:lower — lowercase
function str:lower
    if test (count $argv) -gt 0
        printf '%s' $argv | string lower
    else
        string lower
    end
end

# str:upper — uppercase
function str:upper
    if test (count $argv) -gt 0
        printf '%s' $argv | string upper
    else
        string upper
    end
end

# str:column <n> [delim] — extract column n from piped input
function str:column
    set -l col $argv[1]
    set -l sep (if test -n "$argv[2]"; echo $argv[2]; else; echo ' '; end)
    awk -F"$sep" "{print \$$col}"
end

# str:row <n> — extract row n from piped input
function str:row
    sed -n "$argv[1]p"
end

# utility:round <n> [decimals] — round a number
function utility:round
    set -l num $argv[1]
    set -l dec (if test -n "$argv[2]"; echo $argv[2]; else; echo 0; end)
    printf '%.*f\n' $dec $num
end
```

---

## Standard script template (full library)

Use this when sourcing the library is appropriate:

```fish
#!/usr/bin/env fish

source /path/to/skeleton.fish   # adjust path as needed

set LOG_DIR /tmp/myscript/log
set TMP_DIR /tmp/myscript/tmp
script:initialize               # sets up io, housekeeping, log/tmp dirs
system:load_env                 # load .env files if present

system:require jq               # declare external dependencies early

# --- script logic ---

set tmpfile (system:tempfile json)
io:announce "Fetching data..."
curl -s "$API_BASE/items" > $tmpfile
io:success "Done"

script:safe_exit                # clean up temp files and exit
```

---

## Function quick-reference

### `io:` — user-facing output

```fish
io:print   "Normal line (respects QUIET)"
io:debug   "Debug line to stderr (shown when VERBOSE=0)"
io:alert   "Warning to stderr, script continues"
io:success "Success message with icon"
io:announce "Slow-step notice + 1s pause"
io:progress "In-place status line (loop-safe)"
io:countdown 5 "Deleting in"         # countdown before destructive step
io:confirm                            # [y/N] prompt; auto-yes when FORCE=0
io:ask "Prompt text" default_value   # read a value; capture with $()
io:log "Timestamped line"            # appends to $log_file
io:die "Fatal message"               # print + safe_exit
```

### `str:` — string helpers

```fish
echo " hello " | str:trim            # strip whitespace
str:trim "  hello  "                 # same, via arg
echo "Hello" | str:lower             # lowercase
str:upper "hello"                    # uppercase
echo "crème" | str:ascii             # strip diacritics
str:slugify "Jack & Jill" "-"        # jack-jill
str:title "jack and jill"            # JackAndJill
echo "hello" | str:md5               # MD5, 10 chars
echo "hello" | str:md5 6             # MD5, 6 chars
echo "a b c" | str:column 2          # b
echo "a,b,c" | str:column 2 ","      # b
printf "x\ny\nz\n" | str:row 2       # y
```

### `system:` — OS / filesystem

```fish
set f (system:tempfile json)          # unique temp file; auto-cleaned on exit
system:folder /tmp/app/log 30         # create dir; purge files older than 30d
set p (system:follow_link ./link)     # resolve symlink
system:load_env                       # source .env files near script
system:notify "Done" "MyScript"       # desktop notification
sleep 5 &; system:busy $last_pid "…" # spinner while background pid runs
system:require jq                     # assert binary exists or exit
system:require convert "brew install imagemagick"  # with install hint
```

### `utility:` — numeric helpers

```fish
utility:round 3.14159 2              # → 3.14
set t0 (utility:time)                # high-res timestamp
utility:throughput $t0 100 files     # print ops/sec since t0
```

### `script:` — lifecycle

```fish
script:initialize   # preferred: io:init + housekeeping + log/tmp setup
script:safe_exit    # clean temp files and exit
script:meta         # print runtime summary (version, OS, git, hash)
script:check_version  # warn if upstream git updates exist
script:show_required ./deploy.fish  # list system:require deps in a file
```

### `option:` — option parsing helper

```fish
# Define option:config in your script, then call option:filter
function option:config
    printf '%s\n' \
        'flag|--verbose|-v|Show verbose output' \
        'value|--output|-o|Output file path'
end
option:filter flag   # returns matching option rows
```

---

## Key behavioral rules

1. **Boolean globals use exit-code style**: `0` = enabled/true, `1` = disabled/false.
   - `FORCE=0` → auto-confirm prompts and auto-install missing packages
   - `QUIET=0` → suppress `io:print` output
   - `VERBOSE=0` → show `io:debug` output

2. **Capture return values with `$(...)`**:
   ```fish
   set answer (io:ask "Name" default)
   set tmpfile (system:tempfile json)
   ```

3. **Pipeline helpers read from stdin** when no args given:
   ```fish
   echo " hello " | str:trim
   ```

4. **`system:folder` only cleans paths containing `log`, `temp`, or `tmp`** — safe guard against accidental deletions.

5. **Always end scripts with `script:safe_exit`** (not bare `exit`) to ensure temp files are removed.

6. **Declare dependencies near the top** with `system:require` so failures are fast and clear.

---

## Common patterns

### Non-interactive / CI script

```fish
#!/usr/bin/env fish
source /path/to/skeleton.fish

set FORCE 0        # auto-yes to all prompts
set QUIET 1        # show normal output
set VERBOSE 1      # hide debug output
set LOG_DIR /tmp/ci/log
set TMP_DIR /tmp/ci/tmp
script:initialize
system:require curl
system:require jq

set out (system:tempfile json)
curl -fsSL "$API_URL" > $out
jq '.items[]' $out
script:safe_exit
```

### Timed batch job

```fish
set t0 (utility:time)
for i in (seq 1 $total)
    io:progress "Processing $i / $total"
    # ... work ...
end
io:print ""
utility:throughput $t0 $total items
script:safe_exit
```

### Safe destructive operation

```fish
io:countdown 5 "Dropping database in"
if io:confirm
    do_destructive_thing
    io:success "Done"
else
    io:alert "Aborted"
end
script:safe_exit
```

### Inline-only (no source needed)

```fish
#!/usr/bin/env fish
# Minimal script: only needs str:trim — inline it, skip source

function str:trim
    if test (count $argv) -gt 0
        printf '%s' $argv | string trim
    else
        string trim
    end
end

for line in (cat input.txt)
    echo (str:trim $line)
end
```
