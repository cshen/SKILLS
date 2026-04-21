

################### CS:  6 Nov 2024 13:16 ###########################
################### DO NOT MODIFY BELOW THIS LINE ###################
#####################################################################
set action ''
set error_prefix ''
set execution_day ''
set git_repo_remote ''
set git_repo_root ''
set install_package ''
set os_kernel ''
set os_machine ''
set os_name ''
set os_version ''
set script_basename ''
set script_created ''
set script_extension ''
set script_hash '?'
set script_install_folder ''
set script_install_path ''
set script_lines '?'
set script_modified ''
set script_prefix ''
set script_version ''
set shell_brand ''
set shell_version ''
set temp_files ''
set sourced ''
set piped ''


# NB: CS:  5 Nov 2024 22:45 
# 0 ---> enabled, true
# 1 ---> disabled, false

set IFS '\\n\\t'
set FORCE 1
set help 1

#to enable VERBOSE even before option parsing
set VERBOSE 1
if test ( count argv ) -gt 0;
    and test "$argv[1]" = -v
    set VERBOSE 0
end

#to enable QUIET even before option parsing
set QUIET 1
if test (count argv) -gt 0;
    and test "$argv[1]" = -q
    set QUIET 0
end

set txtReset ''
set txtError ''
set txtInfo ''
set txtInfo ''
set txtWarn ''
set txtBold ''
set txtItalic ''
set txtUnderline ''
set char_succes 'OK '
set char_fail '!! '
set char_alert '?? '
set char_wait '...'
set info_icon '(i)'
set config_icon '[c]'
set clean_icon '[c]'
set require_icon '[pkg]'




#---------- Start of function definition ----------------------------------------------------
### stdio:print/stderr output

# Initialize terminal settings: detect piped/sourced state, enable ANSI color codes,
# and select unicode or ASCII fallback icons. Call once before any other io: function.
function io:init
    set script_started_at (utility:time | string collect; or echo)
    io:debug 'script '"$script_basename"' started at '"$script_started_at"

    # Detect if this file was sourced or executed directly
    # When sourced, status current-filename differs from status filename
    if test (status current-filename) = (status filename) 2>/dev/null
        set sourced 1
    else
        set sourced 0
    end

    # detect if output is piped
    # https://stackoverflow.com/questions/911168/how-can-i-detect-if-my-shell-script-is-running-through-a-pipe
    # 1 --> terminal, thus NOT piped
    # 0 --> piped to cat, thus piped
    test -t 1 && set piped 1 || set piped 0

    if test "$piped" -eq 1; and test -n "$TERM"
        set txtReset (tput sgr0 | string collect; or echo)
        set txtError (tput setaf 160 | string collect; or echo)
        set txtInfo (tput setaf 2 | string collect; or echo)
        set txtWarn (tput setaf 214 | string collect; or echo)
        set txtBold (tput bold | string collect; or echo)
        set txtItalic (tput sitm | string collect; or echo)
        set txtUnderline (tput smul | string collect; or echo)
    end

    # detect if unicode is supported
    test (echo -e '\\xe2\\x82\\xac' | string collect; or echo) = '€' && set unicode 0 || set unicode 1
    if test "$unicode" -eq 0
        set char_succes '✅'
        set char_fail '⛔'
        set char_alert '✴️'
        set char_wait '⏳'
        set info_icon '🌼'
        set config_icon '🌱'
        set clean_icon '🧽'
        set require_icon '🔌'
    end
    set error_prefix "$txtError"'>'"$txtReset"
end


# Print a line to stdout; silently skipped when QUIET=0.
# Example: io:print "Processing $filename"
function io:print
    test "$QUIET" = 0 || printf '%b\\n' "$argv"
    return 0
end

# Print a debug line (in color) to stderr; shown only when VERBOSE=0.
# Example: io:debug "variable x = $x"
function io:debug
    test "$VERBOSE" = 0 && io:print "$txtInfo"'# '"$argv"' '"$txtReset" >&2
    return 0
end

# Print a fatal error message to stderr then call script:safe_exit.
# Example: io:die "Config file not found: $config_path"
function io:die
    io:print "$txtError""$char_fail"' '"$script_basename""$txtReset"': '"$argv" >&2
    #  system:beep
    script:safe_exit
end

# Print a highlighted warning to stderr without stopping the script.
# Example: io:alert "Skipping locked file: $f"
function io:alert
    io:print "$txtWarn""$char_alert""$txtReset"': '"$txtUnderline""$argv""$txtReset" >&2
end

# Print a success message with a checkmark icon to stdout.
# Example: io:success "Backup completed: $dest"
function io:success
    io:print "$txtInfo""$char_succes""$txtReset"'  '"$txtBold""$argv""$txtReset"
end

# Print a notice with a wait icon and pause 1 second; use before a slow operation.
# Example: io:announce "Connecting to $host..."
function io:announce
    io:print "$txtInfo""$char_wait""$txtReset"'  '"$txtItalic""$argv""$txtReset"
    sleep 1
end



# Overwrite the current terminal line with a status update (no newline) — ideal for loops.
# Example: io:progress "Processed $i of $total files"
function io:progress
    if test "$QUIET" != 0
        set -l screen_width (tput cols 2>/dev/null; or echo 80)
        set -l rest_of_line (math "$screen_width - 5")

        if test -n "$piped"; and test "$piped" -eq 0
            io:print "... $argv" >&2
        else
            printf "... %-""$rest_of_line""s\r" "$argv" >&2
        end
    end
end


# Display a live countdown to stderr, then continue. Useful before irreversible operations.
# Example: io:countdown 5 "Deleting data in"
function io:countdown
    set -l seconds (if test -n "$argv[1]"; echo $argv[1]; else; echo 5; end)
    set -l message (if test -n "$argv[2]"; echo $argv[2]; else; echo Countdown; end)

    if test -n "$piped"; and test "$piped" -eq 0
        io:print "$message $seconds seconds"
    else
        for i in (seq 0 (math "$seconds - 1"))
            set -l remaining (math "$seconds - $i")
            io:progress "$txtInfo""$message $remaining seconds""$txtReset"
            sleep 1
        end

        io:print '                         '
    end
end


### interactive
# Prompt the user for y/N confirmation; returns 0 on yes, 1 on no. Skips when FORCE=0.
# Example: io:confirm; and rm -rf $dir
function io:confirm
    test "$FORCE" -eq 0 && return 0
    read -P "Confirm: [y/N] default is No: " -n 1 REPLY
    or set REPLY ""

    if test "$REPLY" = y; or test "$REPLY" = Y
        return 0
    else
        return 1
    end
end


# Prompt the user for a free-form value with an optional default; prints the result.
# Example: set port (io:ask "Port number" 8080)
function io:ask
    set -l DEFAULT $argv[2]
    read -P "$argv[1] [$DEFAULT] > " ANSWER
    or set ANSWER ""

    test -z "$ANSWER" && echo "$DEFAULT" || echo "$ANSWER"
end


# Append a timestamped entry to $log_file. Silently skipped if log_file is empty.
# Example: io:log "Imported $rows rows from $src"
function io:log
    # test -n to check if a variable is NOT empty
    if test -n "$log_file"
        echo (date '+%H:%M:%S' | string collect; or echo)' | '"$argv" >>"$log_file"
    end
end

# Round a floating-point number to the given number of decimal places using awk.
# Example: utility:round 3.14159 2  →  3.14
function utility:round
    set -l number $argv[1]
    set -l decimals $argv[2]
    awk 'BEGIN {print sprintf( "%.'"$decimals"'f" , '"$number"' )};'
end



# 
# Return a high-resolution Unix timestamp as a float; uses perl, python, ruby, or date.
# Example: set t0 (utility:time)
function utility:time
    if test (command -v perl | string collect; or echo)
        perl -MTime::HiRes=time -e 'printf "%f\\n", time'
    else if test (command -v python | string collect; or echo)
        python -c 'import time; print(time.time()) '
    else if test (command -v python3 | string collect; or echo)
        python3 -c 'import time; print(time.time()) '
    else if test (command -v ruby | string collect; or echo)
        ruby -e 'STDOUT.puts(Time.now.to_f)'
    else
        date '+%s.000'
    end
end


# Compute and print ops/sec (or sec/op) since a start timestamp obtained from utility:time.
# Example: utility:throughput $t0 1000 file  →  1000 file finished in 2.5 secs: 400.000 file/sec
function utility:throughput
    set -l time_started $argv[1]
    test -z "$time_started" && set time_started "$script_started_at"
    set -l operations (test -n "$argv[2]" && echo "$argv[2]" || echo 1 )
    set -l name (test -n "$argv[3]" && echo "$argv[3]" || echo operation )

    set -l time_finished (utility:time | string collect; or echo)
    set -l duration (math  "$time_finished"' - '"$time_started" | string collect; or echo)
    set -l seconds (utility:round "$duration" | string collect; or echo)

    if test "$operations" -gt 1
        if test "$operations" -gt $seconds
            set -l ops (math  "$operations"' / '"$duration" | string collect; or echo)
            set ops (utility:round "$ops" 3 | string collect; or echo)
            set duration (utility:round "$duration" 2 | string collect; or echo)
            io:print "$operations"' '"$name"' finished in '"$duration"' secs: '"$ops"' '"$name"'/sec'
        else
            set -l ops (math  "$duration"' / '"$operations" | string collect; or echo)
            set ops (utility:round "$ops" 3 | string collect; or echo)
            set duration (utility:round "$duration" 2 | string collect; or echo)
            io:print "$operations"' '"$name"' finished in '"$duration"' secs: '"$ops"' sec/'"$name"
        end
    else
        set duration (utility:round "$duration" 2 | string collect; or echo)
        io:print "$name"' finished in '"$duration"' secs'
    end
end





# Create a unique temp file path under TMP_DIR (or /tmp) and register it for auto-cleanup.
# Example: set tmp (system:tempfile csv)  →  /tmp/myscript.12345.csv
function system:tempfile

    set -l ext (if test -n "$argv[1]"; echo $argv[1]; else; echo txt; end)

    set -l execution_day (date "+%Y-%m-%d")
    set -l RND ( random 1 10000 )
    set -l file (test -n "$TMP_DIR" && echo "$TMP_DIR" || echo '/tmp')'/'$execution_day'.'$RND'.'$ext

    io:debug "$config_icon"' tmp_file: '"$file"
    set -a temp_files "$file"
    echo "$file"
end


# Source .env, .<script>.env, and <script>.env files from the script's install folder and cwd.
# Variables are exported into the current environment. Useful for secrets and config.
function system:load_env

    if test (pwd | string collect; or echo) = "$script_install_folder"
        set env_files "$script_install_folder"'/.env' "$script_install_folder"'/.'"$script_prefix"'.env' "$script_install_folder"'/'"$script_prefix"'.env'
    else
        set env_files "$script_install_folder"'/.env' "$script_install_folder"'/.'"$script_prefix"'.env' "$script_install_folder"'/'"$script_prefix"'.env' './.env' './.'"$script_prefix"'.env' './'"$script_prefix"'.env'
    end

    for env_file in $env_files
        if test -f "$env_file"
            io:debug "$config_icon"' Read  dotenv: ['"$env_file"']'
            source "$env_file"
        end
    end
end


### string processing

# Strip leading and trailing whitespace. Accepts a piped stream or a direct argument.
# Example: str:trim "  hello  "  →  hello   |   echo "  hi  " | str:trim
function str:trim
    if isatty stdin # not a pipe or redirection
        string trim $argv
    else
        cat | string trim
    end
end

# Convert text to lowercase. Accepts a piped stream or a direct argument.
# Example: str:lower "Hello World"  →  hello world
function str:lower
    isatty stdin && string lower $argv || cat | string lower
end

# Convert text to uppercase. Accepts a piped stream or a direct argument.
# Example: str:upper "hello"  →  HELLO
function str:upper
    isatty stdin && string upper $argv || cat | string upper
end


# Strip diacritics and accents, mapping characters to their plain ASCII equivalents.
# Input must be piped. Example: echo "crème brûlée" | str:ascii  →  creme brulee
function str:ascii
    # remove all characters with accents/diacritics to latin alphabet
    sed 'y/àáâäæãåāǎçćčèéêëēėęěîïííīįìǐłñńôöòóœøōǒõßśšûüǔùǖǘǚǜúūÿžźżÀÁÂÄÆÃÅĀǍÇĆČÈÉÊËĒĖĘĚÎÏÍÍĪĮÌǏŁÑŃÔÖÒÓŒØŌǑÕẞŚŠÛÜǓÙǕǗǙǛÚŪŸŽŹŻ/aaaaaaaaaccceeeeeeeeiiiiiiiilnnooooooooosssuuuuuuuuuuyzzzAAAAAAAAACCCEEEEEEEEIIIIIIIILNNOOOOOOOOOSSSUUUUUUUUUUYZZZ/'

end

# Convert text to a URL-safe lowercase slug. Default separator is "_"; pass second arg to override.
function str:slugify
    # str:slugify <input> <separator>
    # str:slugify "Jack, Jill & Clémence LTD"      => jack-jill-clemence-ltd
    # str:slugify "Jack, Jill & Clémence LTD" "_"  => jack_jill_clemence_ltd
    set separator "$argv[2]"
    test -z "$separator" && set separator _

    string lower "$argv[1]" | str:ascii | awk '{
    gsub(/[\[\]@#$%^&*;,.:()<>!?\/+=_]/," ",$0);
    gsub(/^  */,"",$0);
    gsub(/  *$/,"",$0);
    gsub(/  */,"-",$0);
    gsub(/[^a-z0-9\-]/,"");
    print;
    }' | sed "s/-/$separator/g"
end

# -----------------------------------------
# Convert text to TitleCase, joining words with a separator (default "_").
# Strips accents, punctuation, and limits output to 50 chars.
function str:title -d "Remove non-standard chars from a string"
    # str:title <input> <separator>
    # str:title "Jack, Jill & Clémence LTD"     => JackJillClemenceLtd # CS:  6 Nov 2024 00:59 by default using _
    # str:title "Jack, Jill & Clémence LTD" "_" => Jack_Jill_Clemence_Ltd
    set separator "$argv[2]"
    test -z "$separator" && set separator _

    string lower "$argv[1]" | tr àáâäæãåāçćčèéêëēėęîïííīįìłñńôöòóœøōõßśšûüùúūÿžźż aaaaaaaaccceeeeeeeiiiiiiilnnoooooooosssuuuuuyzzz | awk '{ gsub(/[\[\]@#$%^&*;,.:()<>!?\/+=_-]/," ",$0); print $0; }' | awk '{
    for (i=1; i<=NF; ++i) {
        $i = toupper(substr($i,1,1)) tolower(substr($i,2))
        };
        print $0;
        }' | sed "s/ /$separator/g" | cut -c1-50
end


# Compute the MD5 hash of piped input, truncated to the given length (default 10 chars).
# Example: echo "hello" | str:md5 8  →  5d41402a
function str:md5

    # default length 10
    set length (if test -n "$argv[1]"; echo $argv[1]; else; echo 10; end)

    if command -v md5sum >/dev/null 2>&1
        md5sum | cut -c1-"$length"
    else
        # macos
        md5 | cut -c1-"$length"
    end
end

# Extract a specific column from piped text by position. Optional second arg sets delimiter.
# Input string must be piped
# echo a b c | str:column 2 --> b
function str:column --argument number F

    if test "$F" = ""
        cut -d " " -f $number
    else
        cut -d $F -f $number
    end
end


# Extract a specific line by 1-based index from piped text.
# Example: cat file.txt | str:row 3  →  third line of the file
function str:row --argument index
    sed -n "$index p"
end


# Delete all registered temp files, print runtime duration, then exit 0. Use instead of raw exit.
# Example: script:safe_exit  (called automatically by io:die)
function script:safe_exit

    for temp_file in $temp_files
        if test -f "$temp_file"
		io:debug "Delete temp file [$temp_file]"
		rm -f "$temp_file"
	end
    end

    set -l duration ""
    if test -n "$script_started_at"
        set -l _now (utility:time)
        set -l _secs (utility:round (math "$_now - $script_started_at") 2)
        set duration " after $_secs seconds"
    end

    io:debug "$script_basename finished$duration"
    exit 0
end


# Check if the git repo has upstream commits not yet pulled and prompt the user to update.
# Silently does nothing when the script is not inside a git repository.
function script:check_version

    set -l _old_dir (pwd)
    cd "$script_install_folder" >/dev/null 2>&1
    if test -d '.git'

        set -l remote (git remote -v | grep fetch | awk 'NR == 1 {print $2}' | string collect; or echo)
        io:progress "Check for updates - $remote"

        git remote update >/dev/null 2>&1

        if test (git rev-list --count 'HEAD...HEAD@{upstream}' 2>/dev/null | string collect; or echo) -gt 0
            io:print "Found a recent update of this script - run <<$script_prefix update>> to update"
        else
            io:progress '                                         '
        end
    end

    cd "$_old_dir" >/dev/null 2>&1
end



# Detect and store script path, name, OS, shell, git remote, and version into global vars.
# Must be called before using $script_basename, $os_name, $install_package, etc.
function script:housekeeping

    set script_install_path (realpath (status current-filename))
    set script_basename (basename (realpath (status current-filename)))

    set script_extension (path extension $script_basename)
    set script_prefix (basename $script_basename $script_extension)

    set execution_day (date '+%Y-%m-%d' | string collect; or echo)
    io:debug "$info_icon"' Script path: '"$script_install_path"
    io:debug "$info_icon"' Script prefix: '"$script_prefix"
    io:debug "$info_icon"' Script basename: '"$script_basename"
    io:debug "$info_icon"' Linked path: '"$script_install_path"

    set script_install_folder (path dirname $script_install_path)
    io:debug "$info_icon"' In folder  : '"$script_install_folder"

    if test -f "$script_install_path"
        set script_hash (str:md5  8 <"$script_install_path" | string collect; or echo)
        set script_lines (awk 'END {print NR}' <"$script_install_path" | string collect; or echo)
    end

    # get shell/operating system/versions
    set shell_brand sh
    set shell_version '?'
    test -n "$ZSH_VERSION" && set shell_brand zsh && set shell_version "$ZSH_VERSION"
    test -n "$BASH_VERSION" && set shell_brand bash && set shell_version "$BASH_VERSION"
    test -n "$KSH_VERSION" && set shell_brand ksh && set shell_version "$KSH_VERSION"

    test -n "$FISH_VERSION" && set shell_brand fish && set shell_version "$FISH_VERSION"
    io:debug "$info_icon"' Shell type : '"$shell_brand"' - version '"$shell_version"

    if not test "$shell_brand" = fish
        io:die 'Fish is required'
    end

    set os_kernel (uname -s | string collect; or echo)
    set os_version (uname -r | string collect; or echo)
    set os_machine (uname -m | string collect; or echo)
    set install_package ''

    switch "$os_kernel"
        case 'CYGWIN*' 'MSYS*' 'MINGW*'
            set os_name Windows

        case Darwin
            set os_name (sw_vers -productName | string collect; or echo)
            set os_version (sw_vers -productVersion | string collect; or echo)
            set install_package 'brew install'

        case Linux 'GNU*'
            if test (command -v lsb_release | string collect; or echo)
                # Ubuntu/Raspbian
                set os_name (lsb_release -i | awk -F: '{$1=""; gsub(/^[\\s\\t]+/,"",$2); gsub(/[\\s\\t]+$/,"",$2); print $2}' | string collect; or echo)

                set os_version (lsb_release -r | awk -F: '{$1=""; gsub(/^[\\s\\t]+/,"",$2); gsub(/[\\s\\t]+$/,"",$2); print $2}' | string collect; or echo)
            else
                # Synology, QNAP,
                set os_name Linux
            end

            # Cygwin
            test -x /bin/apt-cyg && set install_package 'apt-cyg install'
            # Synology
            test -x /bin/dpkg && set install_package 'dpkg -i'
            # Synology
            test -x /opt/bin/ipkg && set install_package 'ipkg install'
            # BSD
            test -x /usr/sbin/pkg && set install_package 'pkg install'
            # Arch Linux
            test -x /usr/bin/pacman && set install_package 'pacman -S'
            # Suse Linux
            test -x /usr/bin/zypper && set install_package 'zypper install'
            # Gentoo
            test -x /usr/bin/emerge && set install_package emerge
            # RedHat RHEL/CentOS/Fedora
            test -x /usr/bin/yum && set install_package 'yum install'
            # Alpine
            test -x /usr/bin/apk && set install_package 'apk add'
            # Debian
            test -x /usr/bin/apt-get && set install_package 'apt-get install'
            # Ubuntu
            test -x /usr/bin/apt && set install_package 'apt install'
    end

    io:debug "$info_icon"' System OS  : '"$os_name"' ('"$os_kernel"') '"$os_version"' on '"$os_machine"
    io:debug "$info_icon"' Package utility: '"$install_package"

    # get last modified date of this script
    set script_modified '??'
    # generic linux
    test "$os_kernel" = Linux && set script_modified (stat -c %y "$script_install_path" 2>/dev/null | cut -c1-16 | string collect; or echo)
    # for MacOS

    test "$os_kernel" = Darwin && set script_modified (stat -f '%Sm' "$script_install_path" 2>/dev/null | string collect; or echo)

    io:debug "$info_icon"' Created  : '"$script_created"
    io:debug "$info_icon"' Modified : '"$script_modified"
    io:debug "$info_icon"' Lines    : '"$script_lines"' lines / md5: '"$script_hash"
    io:debug "$info_icon"' User     : '"$USER"'@'"$hostname"

    # if run inside a git repo, detect for which remote repo it is
    if git status >/dev/null 2>&1
        set git_repo_remote (git remote -v | awk '/(fetch)/ {print $2}' | string collect; or echo)
        io:debug "$info_icon"' git remote : '"$git_repo_remote"
        set git_repo_root (git rev-parse --show-toplevel | string collect; or echo)
        io:debug "$info_icon"' git folder : '"$git_repo_root"
    end

    # get script version from VERSION.md file  
    test -f "$script_install_folder"'/VERSION.md' && set script_version (command cat "$script_install_folder"'/VERSION.md' | string collect)
    test -f "$script_install_folder"'/VERSION.txt' && set script_version (command cat "$script_install_folder"'/VERSION.txt' | string collect)

    # get script version from git tag 
    set -l _git_tag (git tag 2>/dev/null | head -1 | string collect; or echo)
    if test -n "$git_repo_root"; and test "$_git_tag" != ""
        set script_version (git tag --sort=version:refname | tail -1)
    end

    io:debug "$info_icon"' Version  : '"$script_version"

end


function script:init
    # Create TMP_DIR and LOG_DIR if configured; open today's log file. Called by script:initialize.
    set log_file ""
    if test -n "$TMP_DIR"
        # clean up TMP folder after 1 day
        system:folder "$TMP_DIR" 1
    end

    if test -n "$LOG_DIR"
        # clean up LOG folder after 1 month
        system:folder "$LOG_DIR" 30
        set log_file $LOG_DIR/$script_prefix.$execution_day".log"
        io:debug "$config_icon log_file: $log_file"
    end
end


# Create a folder if missing; purge files older than max_days (default 365) if it exists.
# The path must contain "log", "temp", or "tmp" as a safety guard against accidental deletes.
# Example: system:folder /var/log/myapp 30
function system:folder --argument folder

    if test -n "$folder"

        # CS:  6 Nov 2024 11:32 
        # to prevent disaster rm, force the folder name must contain log/temp/tmp
        if echo $folder | grep -i -q -E "log|temp|tmp"
            # continue
        else
            # stop
            echo Folder name must contain log/temp/tmp as part of the folder name
            return 1
        end

        set -l max_days ( test -n "$argv[2]" && echo $argv[2] || echo 365 )

        if test ! -d "$folder"
            io:debug "$clean_icon"' Create folder : ['"$folder"']'
            mkdir -p "$folder"
        else
            io:debug "$clean_icon"' Cleanup folder: ['"$folder"'] - delete files older than '"$max_days"' day(s)'
            find "$folder" -mtime +"$max_days" -type f -exec rm -f {} \;
        end
    end
end


# Send a desktop notification on macOS (via osascript) or Linux (via notify-send).
# Example: system:notify "Backup done" "MyScript"
function system:notify
    # cf https://levelup.gitconnected.com/5-modern-bash-scripting-techniques-that-only-a-few-programmers-know-4abb58ddadad
    set -l message $argv[1]
    set -l source ( test -n "$argv[2]" && echo $argv[2] || echo $script_basename )

    io:debug "$info_icon "(set -S source | string collect; or echo)

    if command -v notify-send >/dev/null 2>&1
        notify-send "$source" "$message"
    end

    if command -v osascript >/dev/null 2>&1
        osascript -e 'display notification "'"$message"'" with title "'"$source"'"'
    end
end


# Show an animated spinner in the terminal until a background process (by PID) finishes.
# Example: sleep 5 &; system:busy $last_pid "Compressing archive"
function system:busy
    # show spinner as long as process $pid is running
    set -l pid $argv[1]
    set -l message "$argv[2]"

    # https://stackoverflow.com/questions/3043978/how-to-check-if-a-process-id-pid-exists 
    while ps -p "$pid" &>/dev/null
        for frame in "|" / - "\\"
            printf "\r[ $frame ] %s..." "$message"
            sleep 0.5
        end
    end

    printf "\n"

end


# Assert a binary is on PATH; auto-install (FORCE=0) or die (FORCE=1) when missing.
# Example: system:require jq; system:require convert "brew install imagemagick"
function system:require

    if test -z "$argv[1]"
        io:alert "at least one argument is needed."
        return 0
    end

    set binary $argv[1]
    set path_binary (command -v "$binary" 2>/dev/null | string collect; or echo)
    if test -n "$path_binary"
        io:debug "$require_icon"' required ['"$binary"'] -> '"$path_binary"
        return 0
    end

    # how to install it
    io:alert "$script_basename"' needs ['"$binary"'] but it cannot be found'

    set words (echo $argv[2] | wc -w | string collect; or echo)
    set install_instructions "$install_package"' '$argv[1]

    test "$words" -eq 1 && set install_instructions "$install_package"' '$argv[2]
    test "$words" -gt 1 && set install_instructions $argv[2]

    if test "$FORCE" = 0
        io:announce 'Installing ['$argv[1]'] ...'
        eval "$install_instructions"
    else
        io:alert '1) install package  : '"$install_instructions"
        io:alert '2) check path       : fish_add_path "[path of your binary]"'
        io:die 'Missing program/script ['"$binary"']'
    end
end

# Scan a fish script file for all system:require calls and print a ready-to-run install command.
# Example: script:show_required myscript.fish
#
# CS:  6 Nov 2024 18:07 
# Only works when this file is part of the main script. If this file is sourced, it's not going to work
#
function script:show_required

    set -l main_file ( test -n "$argv[1]" && echo $argv[1] || echo "$script_install_path" )
    if not test -f "$main_file"
        io:alert "$main_file not found"
        return 1
    end

    # xargs removes blank lines 
    echo '# Following packages are needed, you may install them using the command: '
    echo -n "#       $install_package "

    grep -E '^\s*system:require\b' "$main_file" | grep -i -v -E '\(\)|grep|^\s*function|^\s*#' | awk 'NF>1{print $2}' | sort -u | xargs

    return 0
end


# Filter option:config rows by keyword; used internally by the option parser.
# Depends on a user-defined option:config function in the calling script.
function option:filter
    option:config | grep "$argv[1]" | cut -d'|' -f3 | sort | grep -v '^\s*$'
end


# Resolve a symbolic link to its real (physical) path
function system:follow_link --argument link_path
    if test -z "$link_path"
        io:alert "system:follow_link requires a path argument"
        return 1
    end

    if command -v realpath >/dev/null 2>&1
        realpath "$link_path" 2>/dev/null; or echo "$link_path"
    else if command -v readlink >/dev/null 2>&1
        set -l result (readlink -f "$link_path" 2>/dev/null)
        test -n "$result" && echo "$result" || echo "$link_path"
    else
        # Manual resolution: follow chain of symlinks
        set -l target $link_path
        while test -L "$target"
            set -l dest (readlink "$target")
            if string match -q '/*' $dest
                set target $dest
            else
                set target (dirname $target)/$dest
            end
        end
        echo $target
    end
end


# Display script metadata: version, OS, shell, git, file info
function script:meta
    io:print "$txtBold$script_basename $script_version$txtReset"
    io:print "  OS     : $os_name ($os_kernel) $os_version on $os_machine"
    io:print "  Shell  : $shell_brand $shell_version"
    io:print "  Hash   : $script_hash ($script_lines lines)"
    if test -n "$git_repo_remote"
        io:print "  Git    : $git_repo_remote"
    end
    if test -n "$log_file"
        io:print "  Log    : $log_file"
    end
end


# Full initialization: I/O setup + script housekeeping + log/tmp dirs
function script:initialize
    io:init
    script:housekeeping
    script:init
end
