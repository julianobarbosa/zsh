# Theme Customization Guide

Advanced techniques for customizing Oh My Zsh themes.

## Understanding Theme Structure

### Theme File Location

```bash
# Built-in themes
~/.oh-my-zsh/themes/themename.zsh-theme

# Custom themes (recommended for modifications)
${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/themename.zsh-theme

# Custom themes with subdirectory (like powerlevel10k)
${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/themename/themename.zsh-theme
```

### Theme File Anatomy

```zsh
# Example: minimal theme structure

# PROMPT - Left side prompt (required)
PROMPT='%n@%m:%~%# '

# RPROMPT - Right side prompt (optional)
RPROMPT='%T'

# Git prompt configuration (if using git_prompt_info)
ZSH_THEME_GIT_PROMPT_PREFIX="("
ZSH_THEME_GIT_PROMPT_SUFFIX=")"
ZSH_THEME_GIT_PROMPT_DIRTY="*"
ZSH_THEME_GIT_PROMPT_CLEAN=""
```

## Prompt Escape Sequences

### Basic Escapes

| Escape | Meaning | Example Output |
|--------|---------|----------------|
| `%n` | Username | `barbosa` |
| `%m` | Hostname (short) | `macbook` |
| `%M` | Hostname (full) | `macbook.local` |
| `%~` | Current directory (~ for home) | `~/projects` |
| `%/` | Current directory (full path) | `/Users/barbosa/projects` |
| `%c` or `%.` | Current directory only | `projects` |
| `%#` | Prompt char (# for root, % otherwise) | `%` |
| `%?` | Exit code of last command | `0` |
| `%D` | Date (yy-mm-dd) | `24-01-05` |
| `%T` | Time (24-hour HH:MM) | `14:30` |
| `%*` | Time (24-hour HH:MM:SS) | `14:30:45` |
| `%t` or `%@` | Time (12-hour am/pm) | `2:30pm` |
| `%w` | Day and date | `Fri 5` |
| `%W` | Date (mm/dd/yy) | `01/05/24` |
| `%!` | History event number | `1234` |
| `%l` | Current tty | `ttys001` |
| `%j` | Number of background jobs | `2` |

### Conditional Escapes

```zsh
# Show if non-zero exit code
%(?..[%?] )              # Shows "[1] " only on error

# Show if root
%(!.#.$)                 # # for root, $ otherwise

# Truncate directory
%3~                      # Show last 3 components
%4/                      # Show last 4 from root
```

### Colors

```zsh
# Foreground colors
%F{red}text%f            # Red text
%F{green}text%f          # Green text
%F{blue}text%f           # Blue text
%F{yellow}text%f         # Yellow text
%F{cyan}text%f           # Cyan text
%F{magenta}text%f        # Magenta text
%F{white}text%f          # White text
%F{black}text%f          # Black text

# 256 colors
%F{208}text%f            # Orange (256 color)
%F{#ff5500}text%f        # Hex color (if terminal supports)

# Background colors
%K{red}text%k            # Red background
%K{blue}text%k           # Blue background

# Bold, underline, standout
%Bbold%b                 # Bold
%Uunderline%u            # Underline
%Sstandout%s             # Standout (inverse)
```

## Git Integration

### Using git_prompt_info

The `git_prompt_info` function is provided by Oh My Zsh:

```zsh
# In your theme file
PROMPT='%~ $(git_prompt_info)%# '

# Configure appearance
ZSH_THEME_GIT_PROMPT_PREFIX="%F{yellow}git:(%F{red}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%f "
ZSH_THEME_GIT_PROMPT_DIRTY="%F{yellow})%F{red}*"
ZSH_THEME_GIT_PROMPT_CLEAN="%F{yellow})"
```

### Using vcs_info (Native Zsh)

More control but more complex:

```zsh
autoload -Uz vcs_info
precmd() { vcs_info }

# Format strings
zstyle ':vcs_info:git:*' formats '%b'           # Branch name only
zstyle ':vcs_info:git:*' actionformats '%b|%a'  # During rebase/merge

# Enable checking for changes
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' stagedstr '+'
zstyle ':vcs_info:*' unstagedstr '*'
zstyle ':vcs_info:git:*' formats '%b%u%c'

# Use in prompt
setopt PROMPT_SUBST
PROMPT='%~ ${vcs_info_msg_0_} %# '
```

### Advanced Git Status

```zsh
# Custom git status function
git_custom_status() {
  local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  [[ -z "$branch" ]] && return

  local status=""

  # Check for uncommitted changes
  git diff --quiet 2>/dev/null || status+="*"

  # Check for staged changes
  git diff --cached --quiet 2>/dev/null || status+="+"

  # Check for untracked files
  [[ -n $(git ls-files --others --exclude-standard 2>/dev/null) ]] && status+="?"

  echo "($branch$status)"
}

PROMPT='%~ $(git_custom_status) %# '
```

## Creating Custom Themes

### Minimal Custom Theme

```zsh
# ~/.oh-my-zsh/custom/themes/mysimple.zsh-theme

PROMPT='%F{blue}%~%f %F{green}❯%f '
```

### Two-Line Theme

```zsh
# ~/.oh-my-zsh/custom/themes/mytwoline.zsh-theme

PROMPT='%F{cyan}┌─[%f%F{yellow}%n%f%F{cyan}@%f%F{green}%m%f%F{cyan}]─[%f%F{blue}%~%f%F{cyan}]%f
%F{cyan}└─%f%F{red}❯%f '
RPROMPT='%F{gray}%T%f'
```

### Theme with Git

```zsh
# ~/.oh-my-zsh/custom/themes/mygit.zsh-theme

# Git configuration
ZSH_THEME_GIT_PROMPT_PREFIX="%F{yellow}["
ZSH_THEME_GIT_PROMPT_SUFFIX="]%f"
ZSH_THEME_GIT_PROMPT_DIRTY=" %F{red}●%f"
ZSH_THEME_GIT_PROMPT_CLEAN=" %F{green}●%f"

# Prompt
PROMPT='%F{blue}%3~%f $(git_prompt_info)%F{magenta}❯%f '
RPROMPT='%(?.%F{green}✓%f.%F{red}✗ %?%f)'
```

### Theme with Execution Time

```zsh
# ~/.oh-my-zsh/custom/themes/mytimed.zsh-theme

# Track command start time
preexec() {
  cmd_start_time=$SECONDS
}

# Calculate and display duration
precmd() {
  if [[ -n $cmd_start_time ]]; then
    local elapsed=$((SECONDS - cmd_start_time))
    if ((elapsed > 3)); then
      cmd_duration="${elapsed}s"
    else
      cmd_duration=""
    fi
    unset cmd_start_time
  fi
}

PROMPT='%F{blue}%~%f %F{green}❯%f '
RPROMPT='%F{yellow}${cmd_duration}%f'
```

## Powerlevel10k Customization

### Configuration File

After running `p10k configure`, customize `~/.p10k.zsh`:

```zsh
# Left prompt segments
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
  os_icon
  dir
  vcs
  newline
  prompt_char
)

# Right prompt segments
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
  status
  command_execution_time
  background_jobs
  virtualenv
  kubecontext
  time
)

# Segment-specific customization
typeset -g POWERLEVEL9K_DIR_FOREGROUND=31
typeset -g POWERLEVEL9K_DIR_BACKGROUND=clear

# Transient prompt
typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=always

# Instant prompt mode
typeset -g POWERLEVEL9K_INSTANT_PROMPT=verbose
```

### Custom Segments

```zsh
# Add to ~/.p10k.zsh

# Custom segment function
function prompt_my_segment() {
  p10k segment -f 208 -t 'custom text'
}

# Conditional segment
function prompt_docker_context() {
  local ctx=$(docker context show 2>/dev/null)
  [[ $ctx == "default" ]] && return
  p10k segment -f 33 -i '🐳' -t "$ctx"
}

# Add to prompt elements
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
  # ... other segments
  my_segment
  docker_context
)
```

## Environment-Specific Prompts

### Different Prompt for SSH

```zsh
# In theme file or .zshrc
if [[ -n "$SSH_CONNECTION" ]]; then
  PROMPT='%F{red}[SSH]%f %F{yellow}%n@%m%f:%F{blue}%~%f %# '
else
  PROMPT='%F{blue}%~%f %# '
fi
```

### Different Prompt for Root

```zsh
if [[ $UID -eq 0 ]]; then
  PROMPT='%F{red}%n@%m%f:%F{blue}%~%f # '
else
  PROMPT='%F{green}%n%f:%F{blue}%~%f %% '
fi
```

### Per-Directory Themes

```zsh
# In .zshrc, after theme loading
chpwd() {
  if [[ $PWD == */work/* ]]; then
    PROMPT='%F{yellow}[work]%f %F{blue}%~%f %# '
  else
    PROMPT='%F{blue}%~%f %# '
  fi
}
```

## Debugging Themes

### View Current Settings

```bash
# Show current prompt
echo $PROMPT
echo $RPROMPT

# Show git prompt vars
echo $ZSH_THEME_GIT_PROMPT_PREFIX
echo $ZSH_THEME_GIT_PROMPT_SUFFIX

# Test prompt expansion
print -P '%F{red}test%f %~'
```

### Common Issues

**Prompt not updating:**
```zsh
# Ensure PROMPT_SUBST is set
setopt PROMPT_SUBST

# Force prompt refresh
precmd
```

**Colors not showing:**
```bash
# Check terminal color support
echo $TERM
tput colors

# Test colors
for i in {0..255}; do print -P "%F{$i}$i%f"; done
```

**Git status slow:**
```bash
# Time git operations
time git status

# Disable in large repos
git config oh-my-zsh.hide-status 1
```
