#!/usr/bin/env fish

source skeleton.fish

# ── setup: must run first to populate script_basename, install_package, etc. ─
io:init
set LOG_DIR /tmp
set TMP_DIR /tmp
script:initialize
echo "=== script:initialize — done ==="

# ── io: output functions ──────────────────────────────────────────────────────
echo ""
echo "=== io: output ==="
set -S QUIET

io:alert "hello, world. Alert"
io:print "hello, world. Print"

set VERBOSE 0
io:debug "hello, world. Debug"
set VERBOSE 1

io:success "hello, world. Success"
io:announce "hello, world. Announce"

io:progress "io:progress — in-place status line"
sleep 0.3
printf "\n" >&2

io:countdown 2 "io:countdown — resuming in"

# ── io: interactive functions ──────────────────────────────────────────────────
echo ""
echo "=== io: interactive ==="

# io:confirm: FORCE=0 auto-confirms without prompting
echo -n "io:confirm (FORCE=0 → auto-yes): "
set FORCE 0
io:confirm; and echo "confirmed" || echo "declined"
set FORCE 1

# io:confirm: FORCE=1, pipe "y" as stdin answer
echo -n "io:confirm (FORCE=1, piped y): "
echo "y" | io:confirm; and echo "confirmed" || echo "declined"

# io:ask: pipe a value as stdin answer
echo -n "io:ask (piped '42', default 0): "
set result (echo "42" | io:ask "Enter a number" 0)
echo $result

# io:log
set log_file /tmp/fishbone_test.log
io:log "first entry"
sleep 0.3
io:log "second entry"
sleep 0.3
echo "io:log — log file contents:"
cat /tmp/fishbone_test.log

# ── utility: functions ─────────────────────────────────────────────────────────
echo ""
echo "=== utility: ==="

echo -n "utility:round (3.14159, 2dp): "
utility:round 3.14159 2

echo -n "utility:round (2.718, 0dp default): "
utility:round 2.718

set t0 (utility:time)
echo "utility:time: $t0"
sleep 0.2

echo -n "utility:throughput (500 ops since t0): "
utility:throughput $t0 500 record

# ── system: functions ──────────────────────────────────────────────────────────
echo ""
echo "=== system: tempfile ==="

system:tempfile tmp
system:tempfile log
echo "temp_files: $temp_files"

echo ""
echo "=== system:load_env ==="
system:load_env
echo "system:load_env — done"

echo ""
echo "=== system:folder ==="
set -l test_folder /tmp/fishbone_test_log
echo -n "system:folder — create $test_folder: "
system:folder "$test_folder" 7
test -d "$test_folder" && echo "created" || echo "FAILED"
echo -n "system:folder — second call (cleanup existing): "
system:folder "$test_folder" 7
echo "ok"

echo ""
echo "=== system:follow_link ==="
system:follow_link ~/Downloads
system:follow_link ~/bin

echo ""
echo "=== system:notify ==="
system:notify "fishbone test" "test.fish"
echo "system:notify — called"

echo ""
echo "=== system:busy ==="
sleep 1 &
set -l _bg_pid $last_pid
printf "system:busy (1-second bg job): "
system:busy $_bg_pid "background sleep"

# ── str: functions ─────────────────────────────────────────────────────────────
echo ""
echo "=== str: ==="

echo -n "str:trim (arg): "
str:trim "   hello world   "

echo -n "str:trim (piped): "
echo "   piped hello   " | str:trim

echo -n "str:lower (arg): "
str:lower "Hello WORLD"

echo -n "str:lower (piped): "
echo "Hello WORLD" | str:lower

echo -n "str:upper (arg): "
str:upper "hello world"

echo -n "str:upper (piped): "
echo "hello world" | str:upper

echo -n "str:ascii (piped): "
echo "xadsds_ńôöòóœ_" | str:ascii

echo -n "str:slugify (default _ sep): "
str:slugify "Jack, Jull & Clôcccck"

echo -n "str:slugify (- sep): "
str:slugify "Jack, Jull & Clôcccck" "-"

echo -n "str:title (default _ sep): "
str:title "Jack, Jull & Clôcccck, xxx, Jack, Jull & Clôcccck"

echo -n "str:title (space sep): "
str:title "hello world" " "

echo -n "str:md5 (10 chars default): "
echo "sadsadsadsad" | str:md5

echo -n "str:md5 (5 chars): "
echo "sadsadsadsad" | str:md5 5

echo -n "str:column (col 2, space): "
echo "alpha beta gamma" | str:column 2

echo -n "str:column (col 3, comma): "
echo "a,b,c,d" | str:column 3 ,

echo -n "str:row (line 2): "
printf "line1\nline2\nline3\n" | str:row 2

# ── script: metadata functions ─────────────────────────────────────────────────
echo ""
echo "=== script:meta ==="
script:meta

echo ""
echo "=== script:check_version ==="
script:check_version
echo "script:check_version — done"

# ── option:filter ──────────────────────────────────────────────────────────────
echo ""
echo "=== option:filter ==="

function option:config
    echo "flag|--verbose|-v|Show verbose output"
    echo "flag|--quiet|-q|Suppress output"
    echo "value|--output|-o|Output file path"
    echo "value|--count|-n|Number of iterations"
end

echo -n "option:filter (flag): "
option:filter flag | string join ' '

echo -n "option:filter (value): "
option:filter value | string join ' '

# ── system:require — last because FORCE=1 path calls io:die ───────────────────
echo ""
echo "=== system:require ==="
set FORCE 0
system:require
system:require wget
system:require whathehellcommand

echo ""
echo "=== script:show_required ==="
script:show_required
script:show_required test.fish

# system:require with FORCE=1 calls io:die, which exercises script:safe_exit
echo ""
set FORCE 1
system:require whathehell2
