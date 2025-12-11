# Zsh Completion System Reference

Comprehensive guide to zsh's programmable completion system (compsys).

## Contents
- Setup
- Completion Styles (zstyle)
- Completion Functions
- Custom Completions
- Caching
- Debugging

## Setup

### Basic Initialization

```zsh
# Standard initialization
autoload -Uz compinit && compinit

# With security check
autoload -Uz compinit
compinit -u  # Skip security check for faster startup

# Conditional recompilation (faster startup)
autoload -Uz compinit
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C  # Skip security check, use cache
fi
```

### Completion Directories

```zsh
# Add custom completion directory
fpath=(~/.zsh/completions $fpath)

# Regenerate completions
rm -f ~/.zcompdump && compinit
```

## Completion Styles (zstyle)

Format: `zstyle ':completion:*' style-name value`

### Menu and Selection

```zsh
# Enable menu selection (arrow keys to navigate)
zstyle ':completion:*' menu select

# Menu selection only with more than N items
zstyle ':completion:*' menu select=2

# Interactive menu (type to filter)
zstyle ':completion:*' menu select interactive

# No menu, just insert
zstyle ':completion:*' menu no
```

### Matching and Case Sensitivity

```zsh
# Case-insensitive matching
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Case-insensitive + partial word matching
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Fuzzy matching (allows typos)
zstyle ':completion:*' matcher-list '' \
    'm:{a-zA-Z}={A-Za-z}' \
    'r:|[._-]=* r:|=*' \
    'l:|=* r:|=*'

# Substring matching
zstyle ':completion:*' matcher-list 'r:|=*' 'l:|=* r:|=*'
```

### Appearance

```zsh
# Colorize completions using LS_COLORS
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Custom colors for specific types
zstyle ':completion:*:*:kill:*:processes' list-colors \
    '=(#b) #([0-9]#)*=0=01;31'

# Group completions by type
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:corrections' format '%F{green}-- %d (errors: %e) --%f'
zstyle ':completion:*:messages' format '%F{purple}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches found --%f'

# Headers for completion groups
zstyle ':completion:*' format '%B%F{blue}--- %d ---%f%b'

# Separator between groups
zstyle ':completion:*' list-separator '--'
```

### Sorting

```zsh
# Alphabetical sorting
zstyle ':completion:*' sort true

# Sort by modification time (files)
zstyle ':completion:*' file-sort modification

# Sort by access time
zstyle ':completion:*' file-sort access

# Sort by size
zstyle ':completion:*' file-sort size

# Reverse sort
zstyle ':completion:*' file-sort reverse
```

### Caching

```zsh
# Enable completion caching
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

# Rebuild cache after N seconds
zstyle ':completion:*' rehash true
```

### Process Completion

```zsh
# Menu for kill command
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:kill:*' force-list always

# Show all processes for kill
zstyle ':completion:*:*:kill:*:processes' list-colors \
    '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:*:*:*:processes' command \
    'ps -u $USER -o pid,user,comm -w -w'

# Kill by process name
zstyle ':completion:*:*:killall:*' menu yes select
zstyle ':completion:*:killall:*' force-list always
```

### Host and SSH Completion

```zsh
# Complete hostnames from /etc/hosts
zstyle ':completion:*' hosts $(awk '/^[^#]/ {print $2}' /etc/hosts)

# SSH host completion from config
zstyle ':completion:*:ssh:*' hosts $(
    grep -h 'Host ' ~/.ssh/config* 2>/dev/null |
    grep -v '[*?]' |
    awk '{print $2}'
)

# SSH user completion
zstyle ':completion:*:ssh:*' users root $USER

# Ignore known bad hosts
zstyle ':completion:*:*:*:hosts' ignored-patterns \
    'localhost' 'localhost.*' '127.0.0.1' '0.0.0.0' '::1'
```

### File and Directory Completion

```zsh
# Complete only directories for cd
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories

# Ignore certain file patterns
zstyle ':completion:*:*:*:*:files' ignored-patterns \
    '*.pyc' '__pycache__' '.git' 'node_modules'

# Complete . and .. explicitly
zstyle ':completion:*' special-dirs true

# Expand // to /
zstyle ':completion:*' squeeze-slashes true
```

### User Completion

```zsh
# Complete users
zstyle ':completion:*' users root $USER admin

# Ignore system users
zstyle ':completion:*:*:*:users' ignored-patterns \
    avahi bin daemon dbus ftp mail nobody postfix sshd www-data
```

### Man Page Completion

```zsh
# Complete man page sections
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.(^1*)' insert-sections true
```

### Approximate Matching (Fuzzy)

```zsh
# Allow one error
zstyle ':completion:*' completer _complete _approximate
zstyle ':completion:*:approximate:*' max-errors 1 numeric

# Increase errors for longer words
zstyle ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3))numeric)'
```

## Context-Specific Styles

### Pattern: `:completion:function:completer:command:argument:tag`

```zsh
# Specific to git
zstyle ':completion:*:*:git:*' script ~/.zsh/git-completion.bash
zstyle ':completion:*:git-checkout:*' sort false

# Specific to docker
zstyle ':completion:*:*:docker:*' option-stacking yes
zstyle ':completion:*:*:docker-*:*' option-stacking yes

# Specific to npm
zstyle ':completion:*:*:npm:*' ignore-line yes
```

## Completion Functions

### Built-in Completers

```zsh
# Default completers
zstyle ':completion:*' completer _expand _complete _correct _approximate

# Available completers
# _expand      - Expand glob patterns
# _complete    - Standard completion
# _correct     - Spelling correction
# _approximate - Fuzzy matching
# _prefix      - Complete ignoring suffix
# _ignored     - Complete from ignored matches
# _list        - List completions, don't complete
# _oldlist     - Use previous completion list
# _match       - Complete with globbing
# _history     - Complete from history
# _expand_alias - Expand aliases
```

### Custom Completer Order

```zsh
# Try exact match first, then approximate
zstyle ':completion:*' completer _expand _complete _ignored _correct _approximate

# Include history completion
zstyle ':completion:*' completer _expand _complete _ignored _correct _approximate _history
```

## Writing Custom Completions

### Basic Structure

```zsh
#compdef mycommand

_mycommand() {
    local -a commands
    commands=(
        'start:Start the service'
        'stop:Stop the service'
        'status:Show status'
    )

    _describe 'command' commands
}

_mycommand "$@"
```

### With Subcommands

```zsh
#compdef mytool

_mytool() {
    local line state

    _arguments -C \
        "1: :->cmds" \
        "*::arg:->args"

    case "$state" in
        cmds)
            _values "mytool command" \
                "init[Initialize project]" \
                "build[Build project]" \
                "test[Run tests]"
            ;;
        args)
            case $line[1] in
                init)
                    _arguments \
                        '--name[Project name]:name:' \
                        '--template[Template to use]:template:(basic advanced)'
                    ;;
                build)
                    _arguments \
                        '--output[Output directory]:dir:_files -/' \
                        '--release[Build for release]'
                    ;;
                test)
                    _arguments \
                        '--verbose[Verbose output]' \
                        '*:test file:_files -g "*.test.js"'
                    ;;
            esac
            ;;
    esac
}

_mytool "$@"
```

### Using _arguments

```zsh
#compdef myapp

_myapp() {
    _arguments \
        '-h[Show help]' \
        '--help[Show help]' \
        '-v[Verbose output]' \
        '--verbose[Verbose output]' \
        '-c[Config file]:config:_files -g "*.{json,yaml,yml}"' \
        '--config[Config file]:config:_files -g "*.{json,yaml,yml}"' \
        '-o[Output directory]:output:_files -/' \
        '*:input files:_files'
}

_myapp "$@"
```

### Completion Actions

```zsh
# File completion
':file:_files'
':file:_files -g "*.txt"'        # Only .txt files
':file:_files -/'                 # Only directories

# Values from array
local -a opts=(one two three)
':option:($opts)'

# Command output
':user:($(getent passwd | cut -d: -f1))'

# Custom function
':custom:_my_custom_completer'
```

## Debugging

### Show Completion Info

```zsh
# Enable verbose completion
zstyle ':completion:*' verbose yes

# Show description of completion
zstyle ':completion:*:descriptions' format '%B%d%b'

# Debug completion
zstyle ':completion:*' list-prompt '%SAt %p: Hit TAB for more%s'
```

### Trace Completion

```zsh
# Turn on completion debugging
setopt XTRACE

# Trace specific completion
zstyle ':completion:*' verbose yes
zstyle ':completion:*' debug yes
```

### Regenerate Completions

```zsh
# Force rebuild
rm -f ~/.zcompdump* && exec zsh

# Rebuild for specific command
unfunction _mycommand 2>/dev/null
autoload -Uz _mycommand
```

## Common Patterns

### Complete Git Branches

```zsh
_git_branches() {
    local branches
    branches=$(git branch --format='%(refname:short)' 2>/dev/null)
    _values 'branch' ${(f)branches}
}
```

### Complete Docker Containers

```zsh
_docker_containers() {
    local containers
    containers=$(docker ps --format '{{.Names}}' 2>/dev/null)
    _values 'container' ${(f)containers}
}
```

### Complete from History

```zsh
# Complete from command history
zstyle ':completion:*:history-words' stop yes
zstyle ':completion:*:history-words' remove-all-dups yes
zstyle ':completion:*:history-words' list false
zstyle ':completion:*:history-words' menu yes
```

## Performance Tips

1. **Enable caching** for expensive completions
2. **Lazy-load** completion functions with autoload
3. **Limit** expensive completers like `_approximate`
4. **Use** `compinit -C` for faster startup
5. **Avoid** excessive `zstyle` rules
