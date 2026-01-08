#!/usr/bin/env zsh
# Story 2.5: Git Integration for Dotfiles
# Integrate dotfiles with version control using bare repository

# Allow user overrides via environment variables
: ${DOTFILES_REPO:="${HOME}/.dotfiles"}
: ${DOTFILES_GITIGNORE:="${ZSH_TOOL_CONFIG_DIR}/dotfiles.gitignore"}

# Create dotfiles .gitignore template
_zsh_tool_create_dotfiles_gitignore() {
  # Ensure config directory exists
  [[ -d "${DOTFILES_GITIGNORE:h}" ]] || mkdir -p "${DOTFILES_GITIGNORE:h}"

  cat > "$DOTFILES_GITIGNORE" <<'GITIGNORE'
# Exclude sensitive data
.ssh/
.gnupg/
.aws/
.config/gcloud/
*.pem
*.key

# Exclude credentials
.netrc
.gitconfig.local
credentials.json

# Exclude large files
.zsh_history
.cache/
.npm/
.cargo/
node_modules/

# Exclude tool state
.config/zsh-tool/state.json
.config/zsh-tool/backups/
.config/zsh-tool/logs/

# Exclude OS files
.DS_Store
.Trash/
GITIGNORE

  _zsh_tool_log INFO "✓ Created .gitignore template at $DOTFILES_GITIGNORE"
}

# Check if git is configured
_zsh_tool_check_git_config() {
  local git_name=$(git config --global user.name 2>/dev/null)
  local git_email=$(git config --global user.email 2>/dev/null)

  if [[ -z "$git_name" || -z "$git_email" ]]; then
    _zsh_tool_log WARN "Git not configured"
    echo ""
    echo "Please configure git first:"
    echo "  git config --global user.name \"Your Name\""
    echo "  git config --global user.email \"your.email@example.com\""
    echo ""
    return 1
  fi

  return 0
}

# Initialize bare repository for dotfiles
_zsh_tool_git_init_repo() {
  if [[ -d "$DOTFILES_REPO" ]]; then
    _zsh_tool_log WARN "Dotfiles repository already exists at $DOTFILES_REPO"
    return 1
  fi

  # Check git config
  if ! _zsh_tool_check_git_config; then
    return 1
  fi

  _zsh_tool_log INFO "Initializing dotfiles repository (bare)..."

  # Create bare repository (capture git's exit code, not tee's)
  local git_output
  git_output=$(git init --bare "$DOTFILES_REPO" 2>&1)
  local git_result=$?
  echo "$git_output" >> "$ZSH_TOOL_LOG_FILE"

  if [[ $git_result -ne 0 ]]; then
    _zsh_tool_log ERROR "Failed to initialize dotfiles repository"
    return 1
  fi

  # Create gitignore template
  _zsh_tool_create_dotfiles_gitignore

  # Create alias helper
  local alias_cmd="alias dotfiles='git --git-dir=\"\$HOME/.dotfiles\" --work-tree=\"\$HOME\"'"

  # Add to .zshrc.local if not already present
  if [[ ! -f "${HOME}/.zshrc.local" ]] || ! grep -q "dotfiles=" "${HOME}/.zshrc.local" 2>/dev/null; then
    echo "" >> "${HOME}/.zshrc.local"
    echo "# Dotfiles git alias" >> "${HOME}/.zshrc.local"
    echo "$alias_cmd" >> "${HOME}/.zshrc.local"
  fi

  # Set up config to not show untracked files
  git --git-dir="$DOTFILES_REPO" --work-tree="$HOME" config status.showUntrackedFiles no

  # Update state
  _zsh_tool_update_state "git_integration.enabled" "true"
  _zsh_tool_update_state "git_integration.repo_type" "\"bare\""
  _zsh_tool_update_state "git_integration.repo_path" "\"${DOTFILES_REPO}\""

  _zsh_tool_log INFO "✓ Dotfiles repository initialized at $DOTFILES_REPO"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "✓ Dotfiles Git Integration Initialized!"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Usage (reload shell first: exec zsh):"
  echo ""
  echo "  dotfiles status                   # View dotfiles status"
  echo "  dotfiles add .zshrc               # Add file to version control"
  echo "  dotfiles commit -m \"message\"      # Commit changes"
  echo "  dotfiles push -u origin main      # Push to remote"
  echo "  dotfiles pull                     # Pull from remote"
  echo ""
  echo "Configure remote (optional):"
  echo "  dotfiles remote add origin <url>"
  echo ""
  echo "Gitignore template: $DOTFILES_GITIGNORE"
  echo ""

  return 0
}

# Setup remote for dotfiles repository
_zsh_tool_git_setup_remote() {
  local remote_url=$1

  if [[ ! -d "$DOTFILES_REPO" ]]; then
    _zsh_tool_log ERROR "Dotfiles repository not initialized. Run: zsh-tool-git init"
    return 1
  fi

  if [[ -z "$remote_url" ]]; then
    echo -n "Enter remote URL: "
    read -r remote_url
  fi

  if [[ -z "$remote_url" ]]; then
    _zsh_tool_log ERROR "Remote URL cannot be empty"
    return 1
  fi

  _zsh_tool_log INFO "Adding remote: $remote_url"

  # Add remote (capture git's exit code properly)
  local git_output
  git_output=$(git --git-dir="$DOTFILES_REPO" --work-tree="$HOME" remote add origin "$remote_url" 2>&1)
  local git_result=$?
  [[ -n "$git_output" ]] && echo "$git_output" >> "$ZSH_TOOL_LOG_FILE"

  if [[ $git_result -ne 0 ]]; then
    # Maybe remote already exists, try to set URL instead
    git_output=$(git --git-dir="$DOTFILES_REPO" --work-tree="$HOME" remote set-url origin "$remote_url" 2>&1)
    [[ -n "$git_output" ]] && echo "$git_output" >> "$ZSH_TOOL_LOG_FILE"
  fi

  # Update state
  _zsh_tool_update_state "git_integration.remote_url" "\"${remote_url}\""

  _zsh_tool_log INFO "✓ Remote configured: $remote_url"

  return 0
}

# Git status wrapper
_zsh_tool_git_status() {
  if [[ ! -d "$DOTFILES_REPO" ]]; then
    _zsh_tool_log ERROR "Dotfiles repository not initialized. Run: zsh-tool-git init"
    return 1
  fi

  git --git-dir="$DOTFILES_REPO" --work-tree="$HOME" status
}

# Git add wrapper
_zsh_tool_git_add() {
  if [[ ! -d "$DOTFILES_REPO" ]]; then
    _zsh_tool_log ERROR "Dotfiles repository not initialized. Run: zsh-tool-git init"
    return 1
  fi

  git --git-dir="$DOTFILES_REPO" --work-tree="$HOME" add "$@"
}

# Git commit wrapper
_zsh_tool_git_commit() {
  local message=$1

  if [[ ! -d "$DOTFILES_REPO" ]]; then
    _zsh_tool_log ERROR "Dotfiles repository not initialized. Run: zsh-tool-git init"
    return 1
  fi

  if [[ -z "$message" ]]; then
    echo -n "Commit message: "
    read -r message
  fi

  if [[ -z "$message" ]]; then
    _zsh_tool_log ERROR "Commit message cannot be empty"
    return 1
  fi

  git --git-dir="$DOTFILES_REPO" --work-tree="$HOME" commit -m "$message"
  local commit_result=$?

  if [[ $commit_result -eq 0 ]]; then
    _zsh_tool_update_state "git_integration.last_commit" "\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
  fi

  return $commit_result
}

# Git push wrapper
_zsh_tool_git_push() {
  if [[ ! -d "$DOTFILES_REPO" ]]; then
    _zsh_tool_log ERROR "Dotfiles repository not initialized. Run: zsh-tool-git init"
    return 1
  fi

  git --git-dir="$DOTFILES_REPO" --work-tree="$HOME" push "$@"
  local push_result=$?

  if [[ $push_result -eq 0 ]]; then
    _zsh_tool_update_state "git_integration.last_push" "\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
  fi

  return $push_result
}

# Git pull wrapper
_zsh_tool_git_pull() {
  if [[ ! -d "$DOTFILES_REPO" ]]; then
    _zsh_tool_log ERROR "Dotfiles repository not initialized. Run: zsh-tool-git init"
    return 1
  fi

  # Create backup before pull (in case of conflicts)
  _zsh_tool_log INFO "Creating backup before pull..."
  _zsh_tool_create_backup "pre-git-pull"

  git --git-dir="$DOTFILES_REPO" --work-tree="$HOME" pull "$@"
  local pull_result=$?

  if [[ $pull_result -eq 0 ]]; then
    _zsh_tool_update_state "git_integration.last_pull" "\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
  fi

  return $pull_result
}

# Main git integration command
_zsh_tool_git_integration() {
  local subcommand=$1
  shift

  case "$subcommand" in
    init)
      _zsh_tool_git_init_repo "$@"
      ;;
    remote)
      _zsh_tool_git_setup_remote "$@"
      ;;
    status)
      _zsh_tool_git_status "$@"
      ;;
    add)
      _zsh_tool_git_add "$@"
      ;;
    commit)
      _zsh_tool_git_commit "$@"
      ;;
    push)
      _zsh_tool_git_push "$@"
      ;;
    pull)
      _zsh_tool_git_pull "$@"
      ;;
    *)
      echo "Usage: zsh-tool-git <command> [args]"
      echo ""
      echo "Commands:"
      echo "  init              Initialize dotfiles repository"
      echo "  remote <url>      Configure remote URL"
      echo "  status            Show dotfiles status"
      echo "  add <files>       Add files to version control"
      echo "  commit <message>  Commit changes"
      echo "  push              Push to remote"
      echo "  pull              Pull from remote"
      echo ""
      return 1
      ;;
  esac
}
