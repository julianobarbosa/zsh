# Code Duplication Refactoring Plan

**Created:** 2026-01-04
**Priority:** HIGH
**Effort:** 2-3 days
**Risk:** Medium (affects core functionality)

---

## 🎯 Objective

Reduce code duplication from **95% to < 10%** by extracting common patterns from plugins/themes modules into shared abstractions.

---

## 📊 Current Duplication Analysis

### Affected Modules (95% identical):
```
lib/install/plugins.zsh  (354 lines)  ←→  lib/install/themes.zsh  (298 lines)
lib/update/plugins.zsh   (157 lines)  ←→  lib/update/themes.zsh   (176 lines)
```

### Duplicated Patterns:
1. **URL Registry Management** (lines 7-15 in both)
   - `PLUGIN_URLS` vs `THEME_URLS` - identical structure

2. **Git-based Installation** (lines 20-55 in both)
   - `_zsh_tool_install_custom_*()` - 98% identical
   - Only difference: target directory (`plugins/` vs `themes/`)

3. **Git-based Updates** (lines 56-98 in both)
   - `_zsh_tool_update_*()` - 97% identical
   - Only difference: entity name in logs

4. **Built-in Detection** (lines 100-120 in both)
   - `_zsh_tool_is_builtin_*()` - 90% identical
   - Only difference: hardcoded list

5. **Version Management** (lines 8-21 in update modules)
   - `_zsh_tool_get_*_version()` - 100% identical except variable names

6. **Update Checking** (lines 24-53 in update modules)
   - `_zsh_tool_check_*_updates()` - 100% identical except paths

---

## 🏗️ Proposed Architecture

### New Shared Module: `lib/core/component-manager.zsh`

```zsh
#!/usr/bin/env zsh
# Shared component management (plugins, themes, integrations)

# Generic component installation
_zsh_tool_install_git_component() {
  local component_type=$1  # "plugin" or "theme"
  local component_name=$2
  local git_url=$3
  local target_dir=$4

  # Common git clone logic
  # Common error handling
  # Common state tracking
}

# Generic component update
_zsh_tool_update_git_component() {
  local component_type=$1
  local component_name=$2
  local component_dir=$3

  # Common git pull logic
  # Common version tracking
  # Common error handling
}

# Generic component version detection
_zsh_tool_get_component_version() {
  local component_dir=$1
  # Common git describe/rev-parse logic
}

# Generic component update checking
_zsh_tool_check_component_updates() {
  local component_dir=$1
  # Common fetch + SHA comparison
}

# Generic built-in detection
_zsh_tool_is_builtin_component() {
  local component_type=$1
  local component_name=$2
  local -a builtin_list=("${@:3}")

  # Generic array membership check
}
```

### Refactored Plugin Module: `lib/install/plugins.zsh`

```zsh
#!/usr/bin/env zsh
# Plugin management (thin wrapper around component-manager)

source "${ZSH_TOOL_LIB_DIR}/core/component-manager.zsh"

# Plugin-specific configuration
typeset -gA PLUGIN_URLS=(
  zsh-syntax-highlighting "https://github.com/zsh-users/zsh-syntax-highlighting"
  zsh-autosuggestions "https://github.com/zsh-users/zsh-autosuggestions"
)

BUILTIN_PLUGINS=(git docker kubectl npm node python)

# Thin wrapper functions
_zsh_tool_install_custom_plugin() {
  local plugin=$1
  local url=${PLUGIN_URLS[$plugin]}
  local target_dir="${OMZ_CUSTOM_PLUGINS}/${plugin}"

  _zsh_tool_install_git_component "plugin" "$plugin" "$url" "$target_dir"
}

_zsh_tool_update_plugin() {
  local plugin=$1
  local plugin_dir="${OMZ_CUSTOM_PLUGINS}/${plugin}"

  _zsh_tool_update_git_component "plugin" "$plugin" "$plugin_dir"
}

_zsh_tool_is_builtin_plugin() {
  _zsh_tool_is_builtin_component "plugin" "$1" "${BUILTIN_PLUGINS[@]}"
}
```

**LOC Reduction:** 354 lines → ~80 lines (77% reduction)

### Refactored Theme Module: `lib/install/themes.zsh`

```zsh
#!/usr/bin/env zsh
# Theme management (thin wrapper around component-manager)

source "${ZSH_TOOL_LIB_DIR}/core/component-manager.zsh"

# Theme-specific configuration
typeset -gA THEME_URLS=(
  powerlevel10k "https://github.com/romkatv/powerlevel10k"
  spaceship-prompt "https://github.com/spaceship-prompt/spaceship-prompt"
)

BUILTIN_THEMES=(robbyrussell agnoster af-magic...)

# Thin wrapper functions (identical structure to plugins)
_zsh_tool_install_custom_theme() {
  local theme=$1
  local url=${THEME_URLS[$theme]}
  local target_dir="${OMZ_CUSTOM_THEMES}/${theme}"

  _zsh_tool_install_git_component "theme" "$theme" "$url" "$target_dir"
}
```

**LOC Reduction:** 298 lines → ~75 lines (75% reduction)

---

## 📝 Implementation Steps

### Step 1: Create Shared Module (2-3 hours)
- [ ] Create `lib/core/component-manager.zsh`
- [ ] Extract common functions from plugins.zsh
- [ ] Parameterize component type, paths, names
- [ ] Add comprehensive error handling
- [ ] Add logging at DEBUG level

### Step 2: Refactor Plugins (1-2 hours)
- [ ] Backup original `lib/install/plugins.zsh`
- [ ] Rewrite as thin wrapper around component-manager
- [ ] Update function signatures if needed
- [ ] Ensure backward compatibility

### Step 3: Refactor Themes (1-2 hours)
- [ ] Backup original `lib/install/themes.zsh`
- [ ] Rewrite as thin wrapper (copy plugins pattern)
- [ ] Update theme-specific configurations

### Step 4: Update Module (1 hour)
- [ ] Refactor `lib/update/plugins.zsh` to use shared module
- [ ] Refactor `lib/update/themes.zsh` to use shared module

### Step 5: Update Tests (2-3 hours)
- [ ] Update `tests/test-plugins.zsh` to test new architecture
- [ ] Update `tests/test-themes.zsh` to test new architecture
- [ ] Add `tests/test-component-manager.zsh` for core logic
- [ ] Verify all existing tests still pass

### Step 6: Validation (1 hour)
- [ ] Run full test suite
- [ ] Manual testing: install plugin, install theme
- [ ] Manual testing: update plugin, update theme
- [ ] Verify logs show component type correctly

---

## ✅ Success Criteria

1. **Code Reduction:** Total LOC reduced by > 400 lines
2. **Duplication Metric:** Duplication drops from 95% to < 10%
3. **Test Coverage:** All existing tests pass
4. **Backward Compatibility:** No breaking changes to public API
5. **Performance:** No performance regression (< 5% overhead acceptable)

---

## ⚠️ Risks & Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Regression in plugin install | HIGH | Comprehensive testing before merge |
| Abstraction too complex | MEDIUM | Keep wrapper functions simple |
| Merge conflicts with active work | MEDIUM | Coordinate with team, create feature branch |
| Performance overhead from abstraction | LOW | Benchmark before/after, optimize if needed |

---

## 🔄 Rollback Plan

If refactoring introduces issues:
1. Git revert to commit before refactoring
2. Tag current state as `pre-refactor-backup`
3. Use backups created in Steps 2-3

---

## 📦 Deliverables

- [ ] New module: `lib/core/component-manager.zsh` (~200 lines)
- [ ] Refactored: `lib/install/plugins.zsh` (~80 lines, -274)
- [ ] Refactored: `lib/install/themes.zsh` (~75 lines, -223)
- [ ] Refactored: `lib/update/plugins.zsh` (~60 lines, -97)
- [ ] Refactored: `lib/update/themes.zsh` (~60 lines, -116)
- [ ] New tests: `tests/test-component-manager.zsh`
- [ ] Updated: All existing tests passing
- [ ] Documentation: Update architecture docs

**Total LOC:** Before: 1,167 | After: ~475 | **Reduction: 692 lines (59%)**

---

## 📅 Timeline

- **Day 1 Morning:** Steps 1-2 (Create shared module, refactor plugins)
- **Day 1 Afternoon:** Steps 3-4 (Refactor themes, update modules)
- **Day 2 Morning:** Step 5 (Update and create tests)
- **Day 2 Afternoon:** Step 6 (Validation and fixes)
- **Buffer:** +0.5 day for unexpected issues

**Total Estimate:** 2-3 days

---

## 🎯 Next Actions

1. Create feature branch: `refactor/extract-component-manager`
2. Begin Step 1: Create shared module
3. Commit after each step for easy rollback
4. Open PR when validation complete
