# Epic 1 Technical Specification: Core Installation & Configuration System

**Epic:** Core Installation & Configuration System
**Goal:** Enable developers to install and configure a standardized zsh environment with a single command
**Stories:** 7 (23 story points)
**Priority:** P0 - Must Have

---

## Architecture Extract

**Technology Stack:**
- zsh 5.8+
- Oh My Zsh (pinned to stable release or commit SHA)
- Homebrew 4.0+
- git 2.30+
- bats-core 1.10.0 (testing)

**Components:**
- `install/prerequisites.zsh`
- `install/backup.zsh`
- `install/omz.zsh`
- `install/config.zsh`
- `install/plugins.zsh`
- `install/themes.zsh`
- `install/verify.zsh`
- `core/utils.zsh` (shared)

**Data Models:**
- `~/.config/zsh-tool/config.yaml` - Team configuration
- `~/.config/zsh-tool/state.json` - Installation state
- `~/.config/zsh-tool/backups/TIMESTAMP/` - Backup directories
- `~/.zshrc` - User shell configuration

---

## Story 1.1: Prerequisite Detection and Installation

**Component:** `install/prerequisites.zsh`

**Functions:**
```zsh
_zsh_tool_check_prerequisites()    # Main entry, orchestrates checks
_zsh_tool_check_homebrew()         # Returns 0 if installed
_zsh_tool_install_homebrew()       # Runs official install script
_zsh_tool_check_git()              # Returns 0 if installed
_zsh_tool_install_git()            # brew install git
_zsh_tool_check_xcode_cli()        # xcode-select -p
```

**Implementation Notes:**
- Check Homebrew: `command -v brew >/dev/null 2>&1`
- Install Homebrew: Run `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
- Check git: `command -v git`
- Install git: `brew install git`
- Xcode CLI: Prompt user with `xcode-select --install` if missing

**Error Handling:**
- If Homebrew install fails → display instructions, exit 1
- If git install fails → rollback if needed, exit 1
- If Xcode CLI missing → warn user, continue (git via Homebrew works without)

**State Tracking:**
```json
{
  "prerequisites": {
    "homebrew": true,
    "git": true,
    "xcode_cli": false
  }
}
```

**Testing:**
- Mock `brew` command unavailable → triggers install
- Mock `git` unavailable → triggers brew install git
- Idempotency: Run twice, second run skips

---

## Story 1.2: Backup Existing Configuration

**Component:** `install/backup.zsh`

**Functions:**
```zsh
_zsh_tool_create_backup([trigger])      # Creates timestamped backup
_zsh_tool_backup_file(source, dest)    # Copies single file
_zsh_tool_backup_directory(source, dest) # Copies directory
_zsh_tool_generate_manifest()          # Creates backup metadata
```

**Backup Structure:**
```
~/.config/zsh-tool/backups/2025-10-01-120000/
├── .zshrc
├── .zsh_history
├── .oh-my-zsh/custom/ (if exists)
└── manifest.json
```

**Manifest Format:**
```json
{
  "timestamp": "2025-10-01T12:00:00Z",
  "trigger": "pre-install",
  "files": [".zshrc", ".zsh_history"],
  "omz_version": "master-abc123",
  "tool_version": "1.0.0"
}
```

**Implementation Notes:**
- Timestamp format: `date +%Y-%m-%d-%H%M%S`
- Use `cp -R` for directories, `cp` for files
- Create backup directory atomically
- Backup retention: Keep last 10, prune oldest automatically

**Error Handling:**
- If backup directory creation fails → exit 1 (cannot proceed safely)
- If file doesn't exist (new install) → skip, note in manifest
- If disk space insufficient → warn, ask user to free space

**Testing:**
- Backup with existing .zshrc → verify copy
- Backup with no existing config → creates empty backup with manifest
- Multiple backups → verify timestamp uniqueness

---

## Story 1.3: Install Team-Standard Configuration

**Component:** `install/config.zsh`

**Functions:**
```zsh
_zsh_tool_install_config()                  # Main orchestrator
_zsh_tool_fetch_team_config()               # Git clone team config repo
_zsh_tool_parse_config_yaml()               # Load config.yaml
_zsh_tool_generate_zshrc()                  # Create .zshrc from template
_zsh_tool_merge_user_custom()               # Merge .zshrc.local if exists
_zsh_tool_apply_aliases()                   # Write aliases section
_zsh_tool_apply_exports()                   # Write exports section
_zsh_tool_apply_paths()                     # Modify PATH
```

**Configuration Template:**
```zsh
# ===== ZSH-TOOL MANAGED SECTION BEGIN =====
# Team configuration - do not edit manually
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git zsh-syntax-highlighting zsh-autosuggestions)
source $ZSH/oh-my-zsh.sh

# Team aliases
alias gs="git status"
alias gp="git pull"

# Team exports
export EDITOR="vim"

# Team PATH modifications
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
# ===== ZSH-TOOL MANAGED SECTION END =====

# User customizations (load .zshrc.local if exists)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
```

**YAML Parsing:**
- Primary: Use `yq` if available (`brew install yq`)
- Fallback: Pure zsh parsing for simple structures
```zsh
# Example fallback parser
_zsh_tool_yaml_get_plugins() {
  grep '  -' ~/.config/zsh-tool/config.yaml | sed 's/^  - //'
}
```

**Implementation Notes:**
- Marker-based section replacement in .zshrc
- Atomic write: Write to temp file, then `mv`
- Preserve user sections outside markers
- Support .zshrc.local for personal overrides

**Error Handling:**
- If team repo clone fails → use local templates, warn user
- If .zshrc parsing fails → backup exists, can restore
- If merge conflicts (unlikely) → prefer team config, preserve .zshrc.local

**Testing:**
- Install with no existing .zshrc → creates from template
- Install with existing .zshrc → replaces managed section only
- .zshrc.local present → merges correctly
- YAML parsing with yq → validates output
- YAML parsing fallback → validates output matches yq

---

## Story 1.4: Plugin Management System

**Component:** `install/plugins.zsh`

**Functions:**
```zsh
_zsh_tool_install_plugins()                 # Install all from config
_zsh_tool_plugin_install(plugin_name)       # Install single plugin
_zsh_tool_plugin_is_installed(plugin_name)  # Check if exists
_zsh_tool_plugin_update_zshrc(plugin_list)  # Update plugins=() array
```

**Oh My Zsh Plugin Installation:**
```zsh
# Standard plugins (built-in to OMZ)
plugins=(git docker kubectl)

# Custom plugins (external repos)
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

**Implementation Notes:**
- Read plugin list from config.yaml
- Check if plugin directory exists before installing
- For custom plugins, clone from GitHub
- Update `plugins=()` array in .zshrc managed section
- Source .zshrc not required during install (user does at end)

**Plugin Configuration:**
```yaml
plugins:
  - git                          # Built-in
  - docker                       # Built-in
  - zsh-syntax-highlighting      # Custom (auto-detect GitHub URL)
  - zsh-autosuggestions          # Custom
```

**URL Resolution:**
- Maintain plugin registry mapping name → GitHub URL
- Default: `https://github.com/zsh-users/${plugin_name}.git`
- Override in config for team-specific plugins

**Error Handling:**
- Plugin clone fails → skip, warn user, continue with others
- Plugin already exists → skip (idempotent)
- Invalid plugin name → warn, skip

**Testing:**
- Install list of plugins → all installed
- Re-run install → skips existing (idempotent)
- Custom plugin URL → clones correctly
- Plugin clone failure → continues with others

---

## Story 1.5: Theme Installation and Selection

**Component:** `install/themes.zsh`

**Functions:**
```zsh
_zsh_tool_install_theme(theme_name)     # Install and apply theme
_zsh_tool_theme_is_installed(theme)     # Check if available
_zsh_tool_theme_set(theme_name)         # Update ZSH_THEME in .zshrc
_zsh_tool_theme_download(theme_name)    # Download custom theme
```

**Theme Application:**
```zsh
# In .zshrc managed section
ZSH_THEME="robbyrussell"
```

**Implementation Notes:**
- Built-in themes: Already in Oh My Zsh (robbyrussell, agnoster, etc.)
- Custom themes: Download to `${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/`
- Update ZSH_THEME variable in .zshrc managed section
- No need to source .zshrc during install

**Theme Configuration:**
```yaml
themes:
  default: "robbyrussell"
  available:
    - robbyrussell
    - agnoster
    - powerlevel10k  # Custom, requires download
```

**Custom Theme Installation:**
```zsh
# Example: powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k
```

**Error Handling:**
- Theme doesn't exist → fall back to robbyrussell, warn
- Custom theme download fails → use built-in fallback
- Invalid theme name → use default

**Testing:**
- Apply built-in theme → ZSH_THEME updated
- Apply custom theme → downloads and updates
- Theme already installed → skips download (idempotent)

---

## Story 1.6: Personal Customization Layer

**Component:** `core/config.zsh` (merge logic)

**Functions:**
```zsh
_zsh_tool_setup_custom_layer()           # Create .zshrc.local template
_zsh_tool_add_custom_source()            # Add source line to .zshrc
_zsh_tool_preserve_user_config()         # Extract non-managed sections
```

**Customization Pattern:**
```zsh
# .zshrc (managed by zsh-tool)
# ===== ZSH-TOOL MANAGED SECTION BEGIN =====
# Team config here
# ===== ZSH-TOOL MANAGED SECTION END =====

# Source personal customizations
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
```

**`.zshrc.local` Template:**
```zsh
# Personal customizations
# This file is NOT managed by zsh-tool

# Your custom aliases
alias ll='ls -lah'

# Your custom exports
export MY_VAR="value"

# Your custom functions
my_function() {
  echo "custom"
}
```

**Implementation Notes:**
- During install, if existing .zshrc has user content → migrate to .zshrc.local
- Create .zshrc.local template if doesn't exist
- Add source line after managed section
- User edits .zshrc.local for personal changes

**Migration Logic:**
```zsh
# Extract user content outside managed markers
sed -n '/^# ===== ZSH-TOOL MANAGED SECTION BEGIN =====$/,/^# ===== ZSH-TOOL MANAGED SECTION END =====$/!p' \
  ~/.zshrc > ~/.zshrc.local
```

**Error Handling:**
- .zshrc.local already exists → don't overwrite, merge if needed
- Migration extracts empty content → create template

**Testing:**
- Fresh install → creates .zshrc + .zshrc.local template
- Existing .zshrc with user content → migrates to .zshrc.local
- Re-run install → preserves .zshrc.local

---

## Story 1.7: Installation Verification and Summary

**Component:** `install/verify.zsh`

**Functions:**
```zsh
_zsh_tool_verify_installation()          # Main verification
_zsh_tool_check_omz_loaded()             # Verify OMZ functions available
_zsh_tool_check_plugins_loaded()         # Verify plugin functions
_zsh_tool_check_theme_applied()          # Verify theme active
_zsh_tool_display_summary()              # Show installation summary
```

**Verification Checks:**
```zsh
# Oh My Zsh loaded?
[[ -n "$ZSH" && -f "$ZSH/oh-my-zsh.sh" ]]

# Plugins loaded? (check for plugin-specific functions/vars)
# Example: zsh-syntax-highlighting sets ZSH_HIGHLIGHT_VERSION
[[ -n "$ZSH_HIGHLIGHT_VERSION" ]]

# Theme applied?
[[ "$ZSH_THEME" == "robbyrussell" ]]
```

**Installation Summary:**
```
✓ zsh-tool Installation Complete!

Prerequisites:
  ✓ Homebrew 4.2.1
  ✓ git 2.39.0
  ✓ Oh My Zsh (commit abc123)

Configuration:
  ✓ Team .zshrc installed
  ✓ 5 plugins installed: git, docker, zsh-syntax-highlighting, zsh-autosuggestions, kubectl
  ✓ Theme: robbyrussell

Backup created: ~/.config/zsh-tool/backups/2025-10-01-120000/

Next steps:
  1. Reload your shell: exec zsh
  2. (Optional) Customize: edit ~/.zshrc.local
  3. Explore commands: zsh-tool-help

Installation time: 3m 42s
```

**Implementation Notes:**
- Run verification in subshell to test sourcing
- Collect metrics: start time → end time
- Display summary with colored output (green ✓, red ✗)
- Provide next steps clearly

**Error Handling:**
- Verification fails → display what failed, suggest restore
- Partial success → show warnings, prompt to continue or rollback

**Testing:**
- Successful install → all checks pass, summary displayed
- Failed plugin load → displays warning, suggests remedy

---

## Component Dependencies

```
prerequisites.zsh → omz.zsh → config.zsh → plugins.zsh → themes.zsh → verify.zsh
       ↓
   backup.zsh (runs before any modifications)
       ↓
   [All modifications]
       ↓
   verify.zsh
```

---

## Integration Points

**Homebrew:**
- Install Homebrew if missing
- Use `brew install` for git, yq

**Oh My Zsh:**
- Install via official script: `sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"`
- Manage plugins/themes in `$ZSH_CUSTOM`

**git:**
- Clone team config repo (SSH or HTTPS based on user's git config)
- Use user's existing credentials

**File System:**
- Read/write ~/.zshrc atomically
- Create ~/.config/zsh-tool/ structure
- Backup to timestamped directories

---

## State Management

**state.json Structure:**
```json
{
  "version": "1.0.0",
  "installed": true,
  "install_timestamp": "2025-10-01T12:00:00Z",
  "prerequisites": {
    "homebrew": true,
    "git": true,
    "xcode_cli": false
  },
  "omz": {
    "installed": true,
    "version": "master-abc123",
    "path": "/Users/barbosa/.oh-my-zsh"
  },
  "plugins": ["git", "docker", "zsh-syntax-highlighting", "zsh-autosuggestions", "kubectl"],
  "theme": "robbyrussell",
  "last_backup": "2025-10-01-120000",
  "config_repo": "git@github.com:team/zsh-config.git"
}
```

---

## Testing Strategy

**Unit Tests (bats):**
```bash
# tests/epic1/install.bats
@test "prerequisites: detects Homebrew" { ... }
@test "prerequisites: installs git via Homebrew" { ... }
@test "backup: creates timestamped directory" { ... }
@test "backup: generates manifest" { ... }
@test "config: applies team .zshrc" { ... }
@test "config: preserves .zshrc.local" { ... }
@test "plugins: installs from list" { ... }
@test "themes: applies default theme" { ... }
@test "verify: checks all components" { ... }
```

**Integration Test:**
```zsh
#!/usr/bin/env zsh
# tests/integration/epic1-full-install.sh

# Clean environment
rm -rf ~/.config/zsh-tool ~/.oh-my-zsh ~/.zshrc

# Run installation
source lib/zsh-tool.zsh
zsh-tool-install

# Verify
[[ -f ~/.zshrc ]] || exit 1
[[ -d ~/.oh-my-zsh ]] || exit 1
[[ -f ~/.config/zsh-tool/state.json ]] || exit 1
grep "zsh-syntax-highlighting" ~/.zshrc || exit 1

echo "✓ Epic 1 integration test passed"
```

---

## Performance Targets

**Total Epic 1 Time:** < 4 minutes

- Prerequisites (if Homebrew exists): 10s
- Prerequisites (install Homebrew): 2-3 min
- Backup: 5s
- Oh My Zsh install: 30-60s
- Config install: 10s
- Plugin install (5 plugins): 30s
- Theme install: 5s
- Verification: 5s

**Optimization:**
- Parallel plugin clones (if possible)
- Skip already-installed components (idempotency)

---

## Security Considerations

- No credentials stored in config files
- Use user's existing git authentication
- Backup before any destructive operation
- Validate URLs before cloning (whitelist team domains)
- No eval of user input

---

## Epic 1 Implementation Checklist

- [ ] Create repository structure per proposed source tree
- [ ] Implement `core/utils.zsh` (logging, prompts, error handling)
- [ ] Implement Story 1.1: `install/prerequisites.zsh`
- [ ] Implement Story 1.2: `install/backup.zsh`
- [ ] Implement `install/omz.zsh` (prerequisite for 1.3)
- [ ] Implement Story 1.3: `install/config.zsh`
- [ ] Implement Story 1.4: `install/plugins.zsh`
- [ ] Implement Story 1.5: `install/themes.zsh`
- [ ] Implement Story 1.6: Customization layer in `core/config.zsh`
- [ ] Implement Story 1.7: `install/verify.zsh`
- [ ] Create `templates/config.yaml`, `templates/zshrc.template`
- [ ] Write unit tests for all components
- [ ] Write integration test for full Epic 1 flow
- [ ] Run shellcheck on all .zsh files
- [ ] Manual test on macOS 12, 13, 14
- [ ] Update state.json after successful install

---

**Epic 1 Status:** Ready for Implementation
**Estimated Effort:** 23 story points (~5-7 days)
**Dependencies:** None (greenfield)
