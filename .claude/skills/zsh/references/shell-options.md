# Zsh Shell Options Reference

Complete reference for `setopt` and `unsetopt` commands.

## Contents
- Changing Directories
- Completion
- Expansion and Globbing
- History
- Input/Output
- Job Control
- Prompting
- Scripts and Functions
- Shell Emulation
- Zle (Line Editor)

## Changing Directories

| Option | Description |
|--------|-------------|
| `AUTO_CD` | If command is directory name, cd to it |
| `AUTO_PUSHD` | Push old dir to stack on cd |
| `CDABLE_VARS` | cd to var value if not a directory |
| `CD_SILENT` | Don't print directory after cd |
| `CHASE_DOTS` | Resolve `..` in cd before parent |
| `CHASE_LINKS` | Resolve symlinks in cd |
| `POSIX_CD` | POSIX-compliant cd behavior |
| `PUSHD_IGNORE_DUPS` | No duplicates in dir stack |
| `PUSHD_MINUS` | Swap meaning of +/- in stack |
| `PUSHD_SILENT` | Don't print stack after pushd/popd |
| `PUSHD_TO_HOME` | pushd with no args goes home |

**Recommended:**
```zsh
setopt AUTO_CD AUTO_PUSHD PUSHD_IGNORE_DUPS PUSHD_SILENT
```

## Completion

| Option | Description |
|--------|-------------|
| `ALWAYS_LAST_PROMPT` | Return to prompt after completion list |
| `ALWAYS_TO_END` | Move cursor to end after completion |
| `AUTO_LIST` | Auto-list choices on ambiguous completion |
| `AUTO_MENU` | Auto-use menu after second tab |
| `AUTO_NAME_DIRS` | Params with absolute path become dirs |
| `AUTO_PARAM_KEYS` | Auto-remove slash before special chars |
| `AUTO_PARAM_SLASH` | Add slash after directory completion |
| `AUTO_REMOVE_SLASH` | Remove trailing slash before / |
| `BASH_AUTO_LIST` | List on second consecutive tab |
| `COMPLETE_ALIASES` | Don't expand aliases before completion |
| `COMPLETE_IN_WORD` | Complete from both ends of word |
| `GLOB_COMPLETE` | Generate matches with globbing |
| `HASH_LIST_ALL` | Hash entire command table first |
| `LIST_AMBIGUOUS` | List only on unambiguous completion |
| `LIST_BEEP` | Beep on ambiguous completion |
| `LIST_PACKED` | Use variable column widths |
| `LIST_ROWS_FIRST` | Sort completion horizontally |
| `LIST_TYPES` | Show file types in completion list |
| `MENU_COMPLETE` | Cycle through completions on tab |
| `REC_EXACT` | Accept exact matches even if ambiguous |

**Recommended:**
```zsh
setopt AUTO_MENU COMPLETE_IN_WORD ALWAYS_TO_END
```

## Expansion and Globbing

| Option | Description |
|--------|-------------|
| `BAD_PATTERN` | Error on bad glob pattern (default on) |
| `BARE_GLOB_QUAL` | Enable glob qualifiers without (#q) |
| `BRACE_CCL` | Enable {a-z} in brace expansion |
| `CASE_GLOB` | Case-sensitive globbing (default on) |
| `CASE_MATCH` | Case-sensitive regex matching |
| `CSH_NULL_GLOB` | Null glob if at least one pattern matches |
| `EQUALS` | Enable =cmd expansion |
| `EXTENDED_GLOB` | Enable ^, ~, # in patterns |
| `FORCE_FLOAT` | Force float arithmetic |
| `GLOB` | Enable globbing (default on) |
| `GLOB_ASSIGN` | Glob on assignment RHS |
| `GLOB_DOTS` | Include dotfiles in glob |
| `GLOB_STAR_SHORT` | **/ matches zero or more dirs |
| `GLOB_SUBST` | Glob on parameter expansion |
| `HIST_SUBST_PATTERN` | Use pattern in :s modifier |
| `IGNORE_BRACES` | Disable brace expansion |
| `IGNORE_CLOSE_BRACES` | Don't require closing brace |
| `KSH_GLOB` | Enable ksh extended globbing |
| `MAGIC_EQUAL_SUBST` | Enable = expansion in arguments |
| `MARK_DIRS` | Append / to directory globs |
| `MULTIBYTE` | Enable multibyte character support |
| `NO_MATCH` | Error if glob has no matches (default on) |
| `NULL_GLOB` | Empty result for unmatched globs |
| `NUMERIC_GLOB_SORT` | Sort numerically in globs |
| `RC_EXPAND_PARAM` | Array expansion like rc shell |
| `RE_MATCH_PCRE` | Use PCRE for =~ |
| `SH_GLOB` | Disable special glob characters |
| `UNSET` | Allow unset parameter expansion |
| `WARN_CREATE_GLOBAL` | Warn on global variable creation |
| `WARN_NESTED_VAR` | Warn on nested variable scope |

**Recommended:**
```zsh
setopt EXTENDED_GLOB NULL_GLOB GLOB_DOTS
```

## History

| Option | Description |
|--------|-------------|
| `APPEND_HISTORY` | Append to history file (don't overwrite) |
| `BANG_HIST` | Enable ! history expansion |
| `EXTENDED_HISTORY` | Save timestamps in history |
| `HIST_ALLOW_CLOBBER` | Add | to history clobber commands |
| `HIST_BEEP` | Beep on missing history entry |
| `HIST_EXPIRE_DUPS_FIRST` | Remove dups first when trimming |
| `HIST_FCNTL_LOCK` | Use fcntl for history locking |
| `HIST_FIND_NO_DUPS` | Skip dups in history search |
| `HIST_IGNORE_ALL_DUPS` | Remove older dup from history |
| `HIST_IGNORE_DUPS` | Don't store consecutive dups |
| `HIST_IGNORE_SPACE` | Don't store commands starting with space |
| `HIST_LEX_WORDS` | Use lexer for history words |
| `HIST_NO_FUNCTIONS` | Don't store function definitions |
| `HIST_NO_STORE` | Don't store history/fc commands |
| `HIST_REDUCE_BLANKS` | Remove extra blanks |
| `HIST_SAVE_BY_COPY` | Save history atomically |
| `HIST_SAVE_NO_DUPS` | Don't save dups to file |
| `HIST_VERIFY` | Show before executing history expansion |
| `INC_APPEND_HISTORY` | Add to history immediately |
| `INC_APPEND_HISTORY_TIME` | Add with timestamp immediately |
| `SHARE_HISTORY` | Share history between sessions |

**Recommended:**
```zsh
setopt EXTENDED_HISTORY HIST_EXPIRE_DUPS_FIRST HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE HIST_VERIFY SHARE_HISTORY
```

## Input/Output

| Option | Description |
|--------|-------------|
| `ALIASES` | Enable alias expansion (default on) |
| `CLOBBER` | Allow > to overwrite files (default on) |
| `CORRECT` | Try to correct command spelling |
| `CORRECT_ALL` | Correct all arguments spelling |
| `DVORAK` | Use dvorak keyboard for corrections |
| `FLOW_CONTROL` | Enable ^S/^Q flow control |
| `IGNORE_EOF` | Don't exit on EOF (Ctrl-D) |
| `INTERACTIVE_COMMENTS` | Allow # comments in interactive shell |
| `HASH_CMDS` | Hash command locations (default on) |
| `HASH_DIRS` | Hash directories with commands |
| `HASH_EXECUTABLES_ONLY` | Only hash executables |
| `MAIL_WARNING` | Warn if mail file timestamp changed |
| `PATH_DIRS` | Search path for / commands |
| `PATH_SCRIPT` | Use path for script sourcing |
| `PRINT_EIGHT_BIT` | Print 8-bit characters literally |
| `PRINT_EXIT_VALUE` | Print non-zero exit values |
| `RC_QUOTES` | Allow '' for ' in single-quoted strings |
| `RM_STAR_SILENT` | Don't query on rm * |
| `RM_STAR_WAIT` | Wait 10 seconds before rm * |
| `SHORT_LOOPS` | Enable short loop syntax |
| `SHORT_REPEAT` | Enable short repeat syntax |
| `SUN_KEYBOARD_HACK` | Handle trailing ` on Sun keyboards |

**Recommended:**
```zsh
setopt CORRECT INTERACTIVE_COMMENTS NO_CLOBBER RM_STAR_WAIT
```

## Job Control

| Option | Description |
|--------|-------------|
| `AUTO_CONTINUE` | Send CONT to disowned jobs |
| `AUTO_RESUME` | Single-word commands resume jobs |
| `BG_NICE` | Run background jobs at lower priority |
| `CHECK_JOBS` | Warn about jobs on exit |
| `CHECK_RUNNING_JOBS` | Warn about running jobs on exit |
| `HUP` | Send HUP to jobs on exit |
| `LONG_LIST_JOBS` | Use long format for job list |
| `MONITOR` | Enable job control (default) |
| `NOTIFY` | Report job status immediately |
| `POSIX_JOBS` | POSIX-compliant job control |

**Recommended:**
```zsh
setopt NOTIFY LONG_LIST_JOBS
```

## Prompting

| Option | Description |
|--------|-------------|
| `PROMPT_BANG` | Enable ! expansion in prompt |
| `PROMPT_CR` | Print CR before prompt (default on) |
| `PROMPT_PERCENT` | Enable % sequences in prompt (default on) |
| `PROMPT_SP` | Preserve partial line with inverse+space |
| `PROMPT_SUBST` | Enable parameter expansion in prompt |
| `TRANSIENT_RPROMPT` | Remove RPROMPT on accept |

**Recommended:**
```zsh
setopt PROMPT_SUBST
```

## Scripts and Functions

| Option | Description |
|--------|-------------|
| `C_BASES` | Print hex/octal with C prefixes |
| `C_PRECEDENCES` | Use C operator precedence |
| `DEBUG_BEFORE_CMD` | Run DEBUG trap before command |
| `ERR_EXIT` | Exit on non-zero status |
| `ERR_RETURN` | Return on error in function |
| `EVAL_LINENO` | Track line numbers in eval |
| `EXEC` | Execute commands (default on) |
| `FUNCTION_ARGZERO` | Set $0 to function name |
| `LOCAL_LOOPS` | Allow break/continue in functions |
| `LOCAL_OPTIONS` | Restore options on function exit |
| `LOCAL_PATTERNS` | Restore pattern options on function exit |
| `LOCAL_TRAPS` | Restore traps on function exit |
| `MULTI_FUNC_DEF` | Allow multiple function definitions |
| `MULTIOS` | Enable implicit tee/cat |
| `OCTAL_ZEROES` | Treat 0-prefixed numbers as octal |
| `PIPE_FAIL` | Exit status is rightmost non-zero |
| `SOURCE_TRACE` | Print files as they're sourced |
| `TYPESET_SILENT` | Don't print values in typeset |
| `VERBOSE` | Print input lines as read |
| `XTRACE` | Print commands as executed |

**Recommended for scripts:**
```zsh
setopt ERR_EXIT PIPE_FAIL LOCAL_OPTIONS LOCAL_TRAPS
```

## Shell Emulation

| Option | Description |
|--------|-------------|
| `BASH_REMATCH` | Use BASH_REMATCH for regex |
| `BSD_ECHO` | BSD echo behavior |
| `CONTINUE_ON_ERROR` | Continue loop on error |
| `CSH_JUNKIE_HISTORY` | csh-style ! history |
| `CSH_JUNKIE_LOOPS` | csh-style loop termination |
| `CSH_JUNKIE_QUOTES` | csh-style single quotes |
| `CSH_NULLCMD` | csh redirection behavior |
| `KSH_ARRAYS` | Use 0-based arrays like ksh |
| `KSH_AUTOLOAD` | ksh-style autoloading |
| `KSH_OPTION_PRINT` | ksh-style setopt output |
| `KSH_TYPESET` | ksh-style typeset |
| `KSH_ZERO_SUBSCRIPT` | Allow [0] subscript |
| `POSIX_ALIASES` | POSIX-compliant aliases |
| `POSIX_ARGZERO` | POSIX-compliant $0 |
| `POSIX_BUILTINS` | POSIX-compliant builtins |
| `POSIX_IDENTIFIERS` | POSIX-compliant identifiers |
| `POSIX_STRINGS` | POSIX-compliant $'...' |
| `POSIX_TRAPS` | POSIX-compliant traps |
| `SH_FILE_EXPANSION` | sh-style file expansion |
| `SH_NULLCMD` | sh redirection behavior |
| `SH_OPTION_LETTERS` | sh single-letter options |
| `SH_WORD_SPLIT` | sh-style word splitting |
| `TRAPS_ASYNC` | Run traps asynchronously |

**Note:** Avoid SH_WORD_SPLIT and KSH_ARRAYS unless needed for compatibility.

## Zle (Line Editor)

| Option | Description |
|--------|-------------|
| `BEEP` | Beep on error |
| `COMBINING_CHARS` | Handle combining characters |
| `EMACS` | Emacs editing mode |
| `OVERSTRIKE` | Start in overstrike mode |
| `SINGLE_LINE_ZLE` | Single-line editing mode |
| `VI` | Vi editing mode |
| `ZLE` | Enable line editor (default on) |

## Quick Reference

### Recommended Production Options

```zsh
# History
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt SHARE_HISTORY

# Directory navigation
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT

# Globbing
setopt EXTENDED_GLOB
setopt NULL_GLOB

# Safety
setopt NO_CLOBBER
setopt RM_STAR_WAIT

# Completion
setopt AUTO_MENU
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END

# Misc
setopt PROMPT_SUBST
setopt INTERACTIVE_COMMENTS
setopt CORRECT
```

### Script-Safe Options

```zsh
#!/usr/bin/env zsh
setopt ERR_EXIT           # Exit on error
setopt NO_UNSET           # Error on undefined variable
setopt PIPE_FAIL          # Pipelines fail on any error
setopt LOCAL_OPTIONS      # Restore options on function return
```
