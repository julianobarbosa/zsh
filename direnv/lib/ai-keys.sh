#!/usr/bin/env bash
# AI API Keys loader - fetches credentials from 1Password
# Usage: source ~/.direnv/lib/ai-keys.sh && load_ai_keys
#
# This helper fetches AI API keys from 1Password using biometric auth.
# Credentials are never stored on disk - they exist only in memory.
#
# Security model:
#   1Password Vault (encrypted, synced)
#       |
#       v (biometric auth via Touch ID)
#   op inject command
#       |
#       v (stdout, never written to disk)
#   eval in shell session
#       |
#       v (environment variables)
#   AI tools/workflows use credentials
#       |
#       v (on directory exit)
#   direnv unloads variables (clean slate)

load_ai_keys() {
  # Check if op is available
  if ! command -v op &>/dev/null; then
    echo "1Password CLI (op) not found - AI keys not loaded"
    echo "Install with: brew install --cask 1password-cli"
    return 1
  fi

  # Enable session caching (5 minutes) to reduce Touch ID prompts
  export OP_CACHE_EXPIRES_IN=300

  # Check for template file
  local template="${DIRENV_AI_KEYS_TEMPLATE:-$HOME/.direnv/templates/ai-keys.env.tpl}"
  if [[ ! -f "$template" ]]; then
    echo "Template not found: $template"
    echo "Create it with your 1Password secret references:"
    echo "  OPENAI_API_KEY={{ op://AI Keys/OpenAI/credential }}"
    return 1
  fi

  # Check if template has any active (non-commented) secrets
  if ! grep -q "^[^#]*op://" "$template" 2>/dev/null; then
    echo "No active secrets in template: $template"
    echo "Uncomment and configure the secret references"
    return 1
  fi

  # Inject secrets from 1Password
  # op inject reads the template and replaces {{ op://... }} references
  # with actual values fetched from 1Password vault
  local injected
  if injected=$(op inject -i "$template" 2>/dev/null); then
    # Security: Validate output contains only safe export statements
    # Pattern: lines must be empty, comments, or VAR=value / export VAR=value
    local line
    while IFS= read -r line; do
      # Skip empty lines and comments
      [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
      # Validate: must match VAR=value or export VAR=value pattern
      # Allows: MYVAR=value, export MYVAR="value", export MYVAR='value'
      if ! [[ "$line" =~ ^[[:space:]]*(export[[:space:]]+)?[A-Za-z_][A-Za-z0-9_]*= ]]; then
        echo "Security: Invalid line in op inject output, aborting"
        echo "Line: $line"
        return 1
      fi
    done <<< "$injected"

    eval "$injected"
    echo "AI keys loaded ($(date +%H:%M))"
    return 0
  else
    echo "AI keys not loaded - check 1Password authentication"
    echo "Ensure 1Password CLI integration is enabled in 1Password > Settings > Developer"
    return 1
  fi
}

# Unload AI keys (called automatically by direnv on exit)
unload_ai_keys() {
  unset OPENAI_API_KEY
  unset ANTHROPIC_API_KEY
  unset GOOGLE_AI_API_KEY
  unset GITHUB_TOKEN
  unset ELEVENLABS_API_KEY
  unset REPLICATE_API_TOKEN
  unset HUGGINGFACE_TOKEN
  # Add more as needed
}

# Check if AI keys are currently loaded
check_ai_keys() {
  local loaded=0
  local missing=0

  echo "AI Keys Status:"
  echo "==============="

  # Check common AI API keys
  for key in OPENAI_API_KEY ANTHROPIC_API_KEY GOOGLE_AI_API_KEY GITHUB_TOKEN; do
    if [[ -n "${!key}" ]]; then
      echo "  $key: loaded"
      ((loaded++))
    else
      echo "  $key: not set"
      ((missing++))
    fi
  done

  echo ""
  echo "Loaded: $loaded | Not set: $missing"
}
