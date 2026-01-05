# Technical Specification: Epic 3 - Advanced Integrations

**Version:** 1.0
**Author:** Tech Writer Agent (Paige) - BMAD Method
**Date:** 2025-12-17
**Status:** Complete

---

## Epic Overview

**Epic ID:** Epic 3
**Epic Name:** Advanced Integrations
**Priority:** P1 - Should Have
**Dependencies:** Epic 1 (Core Installation), Epic 2 (Maintenance)

### Epic Goal

Provide seamless integration with external shell productivity tools, enabling developers to leverage advanced shell history search (Atuin) and AI-powered command assistance (Amazon Q) within the zsh-tool ecosystem while maintaining compatibility and optimal performance.

### Stories in This Epic

| Story | Name | Points | Status |
|-------|------|--------|--------|
| 13 | Atuin Shell History Integration | 5 | Complete |
| 14 | Amazon Q CLI Integration | 8 | Complete |

### Architecture Extract

**Technology Stack:**
- ZSH shell scripting (POSIX-compatible where possible)
- TOML configuration (Atuin)
- JSON configuration (Amazon Q)
- jq for JSON manipulation
- External tools: `atuin`, `q` (Amazon Q CLI)

**Module Location:** `lib/integrations/`

**Key Patterns:**
- Lazy loading for performance optimization
- Atomic file operations for configuration safety
- Keybinding conflict resolution
- Defensive error handling with return code propagation

---

## Story 13: Atuin Shell History Integration

**Story ID:** ZSHTOOL-002
**As a** developer using zsh-tool
**I want** to integrate Atuin shell history with my zsh environment
**So that** I can search my command history across machines with fuzzy search and sync capabilities

### Acceptance Criteria

- [x] Atuin detection validates installation via `atuin --version`
- [x] Automated installation via curl or Homebrew
- [x] TOML configuration management for Atuin settings
- [x] Shell integration configured in zshrc
- [x] Ctrl+R keybinding properly configured
- [x] Amazon Q compatibility ensures keybinding restoration
- [x] History import from existing zsh history
- [x] Sync setup for multi-machine history
- [x] Health check verifies Atuin functionality

### Functions

#### Detection Functions

```zsh
_atuin_is_installed()
```
**Purpose:** Check if Atuin is installed on the system
**Returns:** 0 if installed, 1 if not
**Implementation Notes:**
- Uses `command -v atuin` for detection
- Silent check with stderr suppression

```zsh
_atuin_detect()
```
**Purpose:** Detect Atuin installation and display version information
**Returns:** 0 if found, 1 if not found
**Implementation Notes:**
- Validates version string format
- Reports version to user if found

#### Installation Functions

```zsh
_atuin_install()
```
**Purpose:** Install Atuin via curl installer or guide user through Homebrew
**Returns:** 0 on success, 1 on failure
**Implementation Notes:**
- Prioritizes curl-based installation (official method)
- Falls back to Homebrew guidance on macOS
- Verifies installation after completion

#### Configuration Functions

```zsh
_atuin_configure_settings()
```
**Purpose:** Configure Atuin TOML settings file
**Config Path:** `~/.config/atuin/config.toml`
**Implementation Notes:**
- Creates config directory if missing
- Sets sensible defaults for:
  - `auto_sync = true`
  - `update_check = true`
  - `search_mode = "fuzzy"`
  - `filter_mode = "host"`
  - `style = "compact"`
- Preserves existing user settings

```zsh
_atuin_configure_shell_integration()
```
**Purpose:** Add Atuin shell integration to zshrc
**Implementation Notes:**
- Adds `eval "$(atuin init zsh)"` to zshrc
- Checks for existing integration to prevent duplicates
- Uses `_atuin_add_to_zshrc_custom()` for safe injection

```zsh
_atuin_configure_keybindings()
```
**Purpose:** Configure Ctrl+R keybinding for Atuin history search
**Implementation Notes:**
- Sets `bindkey '^r' _atuin_search_widget`
- Ensures keybinding loads after shell initialization
- Supports Amazon Q compatibility mode

```zsh
_atuin_configure_amazonq_compatibility()
```
**Purpose:** Restore Atuin Ctrl+R keybinding after Amazon Q loads
**Implementation Notes:**
- Critical for environments where both tools are installed
- Amazon Q intercepts Ctrl+R by default
- Adds restoration hook that runs after Amazon Q initialization
- Uses ZSH precmd hook pattern

#### Utility Functions

```zsh
_atuin_health_check()
```
**Purpose:** Verify Atuin installation and functionality
**Returns:** 0 if healthy, 1 if issues detected
**Checks:**
- Binary exists and is executable
- Config file exists and is readable
- Database is accessible
- Shell integration is loaded

```zsh
_atuin_import_history()
```
**Purpose:** Import existing zsh history into Atuin database
**Implementation Notes:**
- Sources from `~/.zsh_history` or `$HISTFILE`
- Uses `atuin import zsh` command
- Reports import statistics

```zsh
_atuin_setup_sync()
```
**Purpose:** Configure Atuin sync for multi-machine history sharing
**Implementation Notes:**
- Guides user through `atuin register` or `atuin login`
- Configures sync key storage
- Enables automatic sync in config

```zsh
_atuin_add_to_zshrc_custom()
```
**Purpose:** Safely add configuration lines to zshrc
**Parameters:** `$1` - Line to add
**Implementation Notes:**
- Uses `zshrc_custom_inject` pattern from Epic 1
- Prevents duplicate entries
- Atomic write operations

#### Main Entry Point

```zsh
atuin_install_integration()
```
**Purpose:** Main orchestrator for Atuin integration setup
**Returns:** 0 on success, 1 on failure
**Flow:**
1. Detect existing installation
2. Install if not present
3. Configure settings
4. Set up shell integration
5. Configure keybindings
6. Handle Amazon Q compatibility
7. Import existing history (optional)
8. Run health check

### Error Handling

| Error Condition | Handling |
|-----------------|----------|
| Atuin not in PATH | Guide installation, offer Homebrew alternative |
| Config write fails | Use temp file with atomic move |
| History import fails | Log warning, continue setup |
| Sync setup fails | Non-critical, log and continue |
| Keybinding conflict | Apply Amazon Q compatibility fix |

### State Management

**Configuration Files:**
- `~/.config/atuin/config.toml` - Atuin TOML settings
- `~/.local/share/atuin/history.db` - SQLite history database
- `~/.zshrc` or `~/.zshrc.custom` - Shell integration

**State Tracking:**
- `~/.config/zsh-tool/state.json` - Integration enabled status
- Atuin own state via `~/.local/share/atuin/`

---

## Story 14: Amazon Q CLI Integration

**Story ID:** ZSHTOOL-003
**As a** developer using zsh-tool
**I want** to integrate Amazon Q Developer CLI into my zsh environment
**So that** I can leverage AI-powered command line assistance while maintaining my existing workflow tools

### Acceptance Criteria

- [x] Amazon Q CLI detection validates actual Amazon Q (not other `q` commands)
- [x] Guided installation via official .dmg installer
- [x] Shell integration configured with lazy loading
- [x] Atuin compatibility through disabled CLIs list
- [x] Performance optimization via lazy loading
- [x] Configuration management for Amazon Q settings
- [x] Secure .zshrc injection without command injection vulnerabilities
- [x] Health check via `q doctor`
- [x] Comprehensive test coverage

### Functions

#### Detection Functions

```zsh
_amazonq_is_installed()
```
**Purpose:** Check if Amazon Q CLI is installed (not just any `q` command)
**Returns:** 0 if Amazon Q found, 1 if not
**Implementation Notes:**
- Validates version string contains "Amazon Q", "AWS Q", or "q-cli"
- Checks binary path for Amazon Q references
- Prevents false positives from other tools with `q` command

```zsh
_amazonq_detect()
```
**Purpose:** Detect Amazon Q installation and report status
**Returns:** 0 if found, 1 if not found
**Implementation Notes:**
- Uses `_amazonq_is_installed()` for validation
- Reports version and path information

```zsh
_amazonq_validate_cli_name()
```
**Purpose:** Validate that the `q` command is actually Amazon Q CLI
**Returns:** 0 if valid Amazon Q, 1 otherwise
**Implementation Notes:**
- Runs `q --version` and parses output
- Checks for AWS/Amazon Q identifiers
- Added to fix CRITICAL false positive bug

#### Installation Functions

```zsh
_amazonq_install()
```
**Purpose:** Guide user through Amazon Q CLI installation
**Returns:** 0 on success, 1 on failure
**Implementation Notes:**
- Amazon Q requires manual .dmg download (no brew support)
- Provides download URL and instructions
- Waits for user confirmation
- Verifies installation after manual steps
- Handles macOS accessibility permission requirements

#### Configuration Functions

```zsh
_amazonq_configure_shell_integration()
```
**Purpose:** Add Amazon Q shell integration to zshrc
**Implementation Notes:**
- Adds completion and suggestion initialization
- Uses lazy loading wrapper by default
- Integrates with existing zshrc patterns

```zsh
_amazonq_configure_settings()
```
**Purpose:** Configure Amazon Q settings via JSON file
**Config Path:** `~/.aws/q/settings.json`
**Implementation Notes:**
- Uses jq for JSON manipulation (safe, not sed/awk)
- Creates config directory if missing
- Sets recommended defaults
- Handles disabled CLIs list for Atuin compatibility

```zsh
_amazonq_configure_atuin_compatibility()
```
**Purpose:** Add Atuin to Amazon Q's disabled CLIs list
**Implementation Notes:**
- Modifies `settings.json` to exclude Atuin
- Uses jq for safe JSON array manipulation
- Prevents Amazon Q from intercepting Atuin keybindings
- Idempotent - won't add duplicate entries

```zsh
_amazonq_setup_lazy_loading()
```
**Purpose:** Configure lazy loading for Amazon Q to improve shell startup
**Implementation Notes:**
- Creates wrapper alias `q` that loads Amazon Q on first use
- Defers initialization until first command
- Reduces shell startup from +1.8s to near-zero
- Uses ZSH autoload pattern

```zsh
_amazonq_health_check()
```
**Purpose:** Verify Amazon Q functionality
**Returns:** 0 if healthy, 1 if issues detected
**Implementation Notes:**
- Runs `q doctor` for official health check
- Verifies shell integration is loaded
- Checks configuration file accessibility

#### Utility Functions

```zsh
_cleanup_temp()
```
**Purpose:** Clean up temporary files from atomic operations
**Implementation Notes:**
- Removes `.tmp.*` orphaned files
- Called on script exit via trap
- Added to fix orphaned temp file bug

#### Main Entry Point

```zsh
amazonq_install_integration()
```
**Purpose:** Main orchestrator for Amazon Q integration setup
**Returns:** 0 on success, 1 on failure
**Flow:**
1. Detect existing installation (with proper validation)
2. Guide installation if not present
3. Configure shell integration
4. Set up lazy loading
5. Configure Atuin compatibility
6. Update settings
7. Run health check

### Error Handling

| Error Condition | Handling |
|-----------------|----------|
| False positive `q` command | Validate with `_amazonq_validate_cli_name()` |
| Installation cancelled | Return with informative message |
| Settings file missing | Create with defaults |
| jq not available | Fall back to basic JSON write (warn user) |
| Temp file orphaned | Auto-cleanup on next run + trap handling |
| Config write fails | Atomic operation with rollback |

### Security Considerations

1. **Command Injection Prevention:**
   - All user inputs validated before shell execution
   - Uses `printf '%q'` for escaping when necessary
   - No direct string interpolation into commands

2. **Secure File Operations:**
   - Atomic writes using temp files + mv
   - File permissions validated (600 for sensitive configs)
   - No world-readable credential storage

3. **.zshrc Injection Safety:**
   - Validated content patterns before injection
   - No arbitrary code execution paths
   - Documented security audit in story

### State Management

**Configuration Files:**
- `~/.aws/q/settings.json` - Amazon Q settings
- `~/.zshrc` or `~/.zshrc.custom` - Shell integration

**State Tracking:**
- `~/.config/zsh-tool/state.json` - Integration enabled status

---

## Component Dependencies

### External Tools

| Tool | Required For | Version |
|------|--------------|---------|
| atuin | Story 13 | >= 18.0 |
| q (Amazon Q) | Story 14 | Latest |
| jq | JSON manipulation | >= 1.6 |
| curl | Installation | Any |

### Internal Dependencies

| Component | Used By | Purpose |
|-----------|---------|---------|
| `lib/core/utils.zsh` | Both stories | Common utilities, logging |
| `lib/install/config.zsh` | Both stories | Configuration parsing |
| `templates/config.yaml` | Both stories | User configuration |
| `install.sh` | Both stories | Entry point integration |

### File Dependencies

```
lib/
├── core/
│   └── utils.zsh              # Shared utilities
├── install/
│   └── config.zsh             # _zsh_tool_extract_yaml_section()
└── integrations/
    ├── atuin.zsh              # Story 13 implementation
    └── amazon-q.zsh           # Story 14 implementation

templates/
└── config.yaml                # atuin: and amazon_q: sections

tests/
├── test-amazon-q.zsh          # Amazon Q test suite
└── test-amazon-q-edge-cases.zsh # Edge case coverage
```

---

## Testing Strategy

### Story 13: Atuin Tests

| Test Case | Description | Type |
|-----------|-------------|------|
| `test_atuin_detection` | Verify Atuin detection logic | Unit |
| `test_atuin_config_creation` | Test TOML config generation | Unit |
| `test_atuin_shell_integration` | Verify zshrc integration | Integration |
| `test_atuin_keybinding` | Test Ctrl+R binding setup | Integration |
| `test_atuin_amazonq_compat` | Test keybinding restoration | Integration |
| `test_atuin_history_import` | Test history import | Integration |

### Story 14: Amazon Q Tests

| Test Case | Description | Type |
|-----------|-------------|------|
| `test_amazonq_detection_real` | Validate real Amazon Q detection | Unit |
| `test_amazonq_false_positive` | Reject non-Amazon Q `q` commands | Unit |
| `test_amazonq_settings_json` | Test JSON config manipulation | Unit |
| `test_amazonq_lazy_loading` | Verify lazy load wrapper | Integration |
| `test_amazonq_atuin_compat` | Test disabled CLIs configuration | Integration |
| `test_amazonq_temp_cleanup` | Verify orphan file cleanup | Unit |
| `test_amazonq_atomic_write` | Test atomic file operations | Unit |
| `test_amazonq_zshrc_injection` | Verify secure injection | Security |
| `test_amazonq_input_validation` | Test input sanitization | Security |

### Test Execution

```bash
# Run all Epic 3 tests
./tests/run-all-tests.sh

# Run specific test suites
./tests/test-amazon-q.zsh
./tests/test-amazon-q-edge-cases.zsh
```

### Test Coverage Goals

- Unit test coverage: >= 80%
- Integration test coverage: >= 70%
- Security test coverage: All injection vectors tested

---

## Performance Considerations

### Shell Startup Impact

| Integration | Without Lazy Load | With Lazy Load |
|-------------|-------------------|----------------|
| Atuin | +50ms | +5ms |
| Amazon Q | +1,800ms | +0ms (deferred) |

### Recommendations

1. **Enable lazy loading** (default) for both integrations
2. Amazon Q lazy loading is critical due to 1.8s startup overhead
3. Atuin impact is minimal but lazy loading still recommended
4. Monitor `zsh -i -c exit` time after integration

---

## Known Issues and Mitigations

### Issue 1: Amazon Q Intercepts Ctrl+R

**Problem:** Amazon Q captures Ctrl+R even when Atuin is in disabled CLIs
**Mitigation:** `_atuin_configure_amazonq_compatibility()` restores keybinding
**Upstream:** GitHub issue #2672

### Issue 2: Amazon Q Performance

**Problem:** 11ms per command overhead, 1.8s startup delay
**Mitigation:** Lazy loading defers initialization
**Upstream:** GitHub issue #844

### Issue 3: False Positive Detection

**Problem:** Other tools using `q` command were detected as Amazon Q
**Fix:** Added `_amazonq_validate_cli_name()` with version string validation
**Status:** FIXED

---

## Implementation Checklist

### Story 13: Atuin Integration

- [x] Create `lib/integrations/atuin.zsh` module
- [x] Implement detection functions
- [x] Implement installation functions
- [x] Implement configuration functions
- [x] Implement Amazon Q compatibility
- [x] Add shell integration to zshrc patterns
- [x] Update `templates/config.yaml` with atuin section
- [x] Document in README.md

### Story 14: Amazon Q Integration

- [x] Create `lib/integrations/amazon-q.zsh` module
- [x] Implement detection with validation
- [x] Implement guided installation
- [x] Implement lazy loading
- [x] Implement Atuin compatibility
- [x] Add jq-based JSON configuration
- [x] Create test suite
- [x] Fix false positive detection bug
- [x] Fix orphaned temp file cleanup
- [x] Fix YAML parsing robustness
- [x] Security audit for injection vulnerabilities
- [x] Update `templates/config.yaml` with amazon_q section
- [x] Document in README.md
- [x] Create comprehensive story documentation

---

## Appendix A: Configuration Schema

### config.yaml - Atuin Section

```yaml
atuin:
  enabled: true
  auto_sync: true
  search_mode: "fuzzy"      # fuzzy, prefix, fulltext
  filter_mode: "host"       # global, host, session, directory
  style: "compact"          # compact, full
  inline_height: 40
```

### config.yaml - Amazon Q Section

```yaml
amazon_q:
  enabled: true
  lazy_loading: true
  disabled_clis:
    - atuin
    - fzf
  telemetry: false
```

---

## Appendix B: File Locations

### Atuin

| Purpose | Path |
|---------|------|
| Config | `~/.config/atuin/config.toml` |
| Database | `~/.local/share/atuin/history.db` |
| Key | `~/.local/share/atuin/key` |

### Amazon Q

| Purpose | Path |
|---------|------|
| Settings | `~/.aws/q/settings.json` |
| App | `/Applications/Amazon Q.app` |
| CLI | `/usr/local/bin/q` or via app |

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-12-17 | Paige (Tech Writer) | Initial comprehensive specification |

---

**Generated by:** BMAD Method v6 - Tech Writer Agent
**Template Version:** 1.0 (based on tech-spec-epic-1.md format)
