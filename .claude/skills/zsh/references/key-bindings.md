# Zsh Key Bindings Reference

Complete reference for zsh line editor (ZLE) key bindings.

## Contents
- Binding Modes
- Common Key Sequences
- Movement Commands
- Editing Commands
- History Commands
- Custom Bindings
- Vi Mode

## Binding Modes

```zsh
# Emacs mode (default)
bindkey -e

# Vi mode
bindkey -v

# Show current mode
bindkey -l              # List keymaps
bindkey -lL main        # Show main keymap mode

# Use specific keymap
bindkey -M emacs        # Emacs bindings
bindkey -M viins        # Vi insert mode
bindkey -M vicmd        # Vi command mode
```

## Key Sequence Notation

```
^A       Ctrl+A
^[       Escape (Meta prefix)
^[a      Alt+A or Escape then A
^[[A     Up arrow
^[[B     Down arrow
^[[C     Right arrow
^[[D     Left arrow
^[[H     Home
^[[F     End
^[[3~    Delete
^[[5~    Page Up
^[[6~    Page Down
^[[1;5C  Ctrl+Right
^[[1;5D  Ctrl+Left
```

### Finding Key Codes

```zsh
# Show key sequence interactively
cat -v
# Then press keys and see output

# Or use showkey
showkey -a

# In zsh, Ctrl+V then key shows escape sequence
# Press Ctrl+V then Up arrow shows: ^[[A
```

## Movement Commands (Emacs Mode)

### Character Movement

```zsh
bindkey '^B' backward-char          # Ctrl+B: Move left
bindkey '^F' forward-char           # Ctrl+F: Move right

# Arrow keys (already bound)
bindkey '^[[D' backward-char        # Left arrow
bindkey '^[[C' forward-char         # Right arrow
```

### Word Movement

```zsh
bindkey '^[b' backward-word         # Alt+B: Back one word
bindkey '^[f' forward-word          # Alt+F: Forward one word

# Ctrl+Arrow
bindkey '^[[1;5D' backward-word     # Ctrl+Left
bindkey '^[[1;5C' forward-word      # Ctrl+Right

# Alternative sequences (depends on terminal)
bindkey '^[^[[D' backward-word      # Alt+Left
bindkey '^[^[[C' forward-word       # Alt+Right
```

### Line Movement

```zsh
bindkey '^A' beginning-of-line      # Ctrl+A: Start of line
bindkey '^E' end-of-line            # Ctrl+E: End of line

# Home/End keys
bindkey '^[[H' beginning-of-line    # Home
bindkey '^[[F' end-of-line          # End
bindkey '^[[1~' beginning-of-line   # Home (alternate)
bindkey '^[[4~' end-of-line         # End (alternate)
```

## Editing Commands (Emacs Mode)

### Deletion

```zsh
bindkey '^D' delete-char            # Ctrl+D: Delete char
bindkey '^H' backward-delete-char   # Ctrl+H: Backspace
bindkey '^?' backward-delete-char   # Backspace key

bindkey '^W' backward-kill-word     # Ctrl+W: Delete word back
bindkey '^[d' kill-word             # Alt+D: Delete word forward

bindkey '^K' kill-line              # Ctrl+K: Delete to end
bindkey '^U' backward-kill-line     # Ctrl+U: Delete to start

bindkey '^[[3~' delete-char         # Delete key
```

### Cut/Copy/Paste (Kill Ring)

```zsh
bindkey '^Y' yank                   # Ctrl+Y: Paste
bindkey '^[y' yank-pop              # Alt+Y: Cycle paste history

# Kill region (with mark)
bindkey '^@' set-mark-command       # Ctrl+Space: Set mark
bindkey '^[w' copy-region-as-kill   # Alt+W: Copy region
bindkey '^W' kill-region            # Ctrl+W: Cut region
```

### Case Modification

```zsh
bindkey '^[u' up-case-word          # Alt+U: UPPERCASE word
bindkey '^[l' down-case-word        # Alt+L: lowercase word
bindkey '^[c' capitalize-word       # Alt+C: Capitalize word
```

### Transposition

```zsh
bindkey '^T' transpose-chars        # Ctrl+T: Swap chars
bindkey '^[t' transpose-words       # Alt+T: Swap words
```

### Undo

```zsh
bindkey '^_' undo                   # Ctrl+_: Undo
bindkey '^Xu' undo                  # Ctrl+X, u: Undo
bindkey '^[_' redo                  # Alt+_: Redo
```

## History Commands

### Basic Navigation

```zsh
bindkey '^P' up-line-or-history     # Ctrl+P: Previous history
bindkey '^N' down-line-or-history   # Ctrl+N: Next history

# Arrow keys
bindkey '^[[A' up-line-or-history   # Up arrow
bindkey '^[[B' down-line-or-history # Down arrow
```

### Search

```zsh
bindkey '^R' history-incremental-search-backward  # Ctrl+R: Search back
bindkey '^S' history-incremental-search-forward   # Ctrl+S: Search forward

# Pattern search
bindkey '^[p' history-search-backward  # Alt+P: Search with prefix
bindkey '^[n' history-search-forward   # Alt+N: Search with prefix
```

### Prefix Search (Recommended)

```zsh
# Search history with current input as prefix
bindkey '^[[A' history-search-backward  # Up: Search with prefix
bindkey '^[[B' history-search-forward   # Down: Search with prefix

# Example: type "git" then Up shows previous git commands
```

### History Expansion

```zsh
bindkey '^[!' expand-history        # Alt+!: Expand history
bindkey ' ' magic-space             # Space: Expand history inline
```

## Completion Bindings

```zsh
bindkey '^I' complete-word          # Tab: Complete
bindkey '^[[Z' reverse-menu-complete # Shift+Tab: Reverse complete

# Menu selection (in completion)
bindkey -M menuselect '^[[Z' reverse-menu-complete
bindkey -M menuselect '^M' .accept-line  # Enter: Accept

# Expand and complete
bindkey '^X*' expand-word           # Ctrl+X *: Expand glob
```

## Miscellaneous

```zsh
bindkey '^L' clear-screen           # Ctrl+L: Clear screen
bindkey '^Z' push-input             # Ctrl+Z: Push line to stack

bindkey '^[.' insert-last-word      # Alt+.: Insert last arg
bindkey '^[_' insert-last-word      # Alt+_: Insert last arg

bindkey '^Q' push-line              # Ctrl+Q: Save line, edit next
bindkey '^[q' push-line             # Alt+Q: Same

bindkey '^Xr' history-incremental-search-backward
bindkey '^Xs' history-incremental-search-forward
```

## Custom Bindings

### Basic Binding

```zsh
# Bind key to widget
bindkey '^O' clear-screen

# Bind to run command
bindkey -s '^X^L' 'ls -la^M'        # Ctrl+X Ctrl+L: Run ls -la
```

### Custom Widgets

```zsh
# Define custom widget
my-widget() {
    BUFFER="git status"
    zle accept-line
}
zle -N my-widget
bindkey '^G^S' my-widget

# Widget that modifies buffer
insert-date() {
    LBUFFER+=$(date +%Y-%m-%d)
}
zle -N insert-date
bindkey '^[d' insert-date

# Widget with cursor position
surround-with-quotes() {
    BUFFER="\"${BUFFER}\""
    CURSOR=$((CURSOR + 1))
}
zle -N surround-with-quotes
bindkey '^[\"' surround-with-quotes
```

### Useful Custom Widgets

```zsh
# Edit command in editor
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# Insert sudo at beginning
insert-sudo() {
    BUFFER="sudo $BUFFER"
    CURSOR+=5
}
zle -N insert-sudo
bindkey '^[s' insert-sudo

# cd to parent directory
cd-parent() {
    BUFFER="cd .."
    zle accept-line
}
zle -N cd-parent
bindkey '^[u' cd-parent

# Accept autosuggestion (for zsh-autosuggestions)
bindkey '^ ' autosuggest-accept    # Ctrl+Space
bindkey '^[[I' autosuggest-accept  # Terminal focus event
```

## Vi Mode

### Enable Vi Mode

```zsh
bindkey -v

# Reduce mode switch delay
export KEYTIMEOUT=1
```

### Vi Insert Mode (viins)

```zsh
bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^H' backward-delete-char
bindkey -M viins '^W' backward-kill-word
bindkey -M viins '^U' backward-kill-line
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line
bindkey -M viins '^R' history-incremental-search-backward
```

### Vi Command Mode (vicmd)

Standard vi bindings work: h, j, k, l, w, b, 0, $, etc.

```zsh
# Additional bindings
bindkey -M vicmd 'H' beginning-of-line
bindkey -M vicmd 'L' end-of-line
bindkey -M vicmd 'k' up-line-or-history
bindkey -M vicmd 'j' down-line-or-history
```

### Vi Mode Indicator

```zsh
# Change cursor based on mode
function zle-keymap-select {
    case $KEYMAP in
        vicmd)      echo -ne '\e[2 q' ;;  # Block cursor
        viins|main) echo -ne '\e[6 q' ;;  # Beam cursor
    esac
}
zle -N zle-keymap-select

# Initialize cursor
function zle-line-init {
    echo -ne '\e[6 q'
}
zle -N zle-line-init
```

## Show All Bindings

```zsh
# List all bindings
bindkey -L

# List specific keymap
bindkey -M emacs -L
bindkey -M viins -L
bindkey -M vicmd -L

# Find what a key does
bindkey '^R'

# Find all bindings for a command
bindkey | grep search
```

## Recommended Configuration

```zsh
# ~/.zshrc key bindings section

# Use emacs mode
bindkey -e

# Better history search
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# Word movement with Ctrl+Arrow
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# Home/End
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line

# Delete key
bindkey '^[[3~' delete-char

# Edit in $EDITOR
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# Insert last word
bindkey '^[.' insert-last-word

# Clear screen
bindkey '^L' clear-screen
```
