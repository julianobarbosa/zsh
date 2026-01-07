# AI API Keys - fetched from 1Password
# =====================================
#
# This template is used by direnv + 1Password integration to securely
# load API keys into your shell environment using biometric authentication.
#
# HOW IT WORKS:
#   1. You define secret references using op:// URIs
#   2. When you cd into a directory with .envrc that calls load_ai_keys
#   3. 1Password CLI (op inject) replaces references with actual values
#   4. Values are loaded into environment variables
#   5. When you leave the directory, direnv unloads the variables
#
# FORMAT: VARIABLE_NAME={{ op://Vault/Item/field }}
#
# VAULT STRUCTURE EXAMPLE:
#   AI Keys (vault)
#   ├── OpenAI
#   │   └── credential (API key)
#   ├── Anthropic
#   │   └── credential (API key)
#   ├── Google AI
#   │   └── credential (API key)
#   └── ElevenLabs
#       └── credential (API key)
#
#   Development (vault)
#   ├── GitHub
#   │   └── token (PAT)
#   └── npm
#       └── token
#
# INSTRUCTIONS:
#   1. Create items in your 1Password vault with your API keys
#   2. Uncomment and update the lines below to match your vault structure
#   3. Test with: cd /your/project && direnv allow
#
# SECURITY NOTES:
#   - This file is safe to commit (no actual secrets)
#   - Secrets are fetched on-demand and never stored on disk
#   - Touch ID authentication required for each session
#   - 5-minute session cache reduces auth prompts
#
# =====================================

# AI Model Providers
# OPENAI_API_KEY={{ op://AI Keys/OpenAI/credential }}
# ANTHROPIC_API_KEY={{ op://AI Keys/Anthropic/credential }}
# GOOGLE_AI_API_KEY={{ op://AI Keys/Google AI/credential }}

# Audio/Voice AI
# ELEVENLABS_API_KEY={{ op://AI Keys/ElevenLabs/credential }}

# Image/Video AI
# REPLICATE_API_TOKEN={{ op://AI Keys/Replicate/credential }}
# STABILITY_API_KEY={{ op://AI Keys/Stability AI/credential }}

# ML Platforms
# HUGGINGFACE_TOKEN={{ op://AI Keys/Hugging Face/token }}

# Development Tools
# GITHUB_TOKEN={{ op://Development/GitHub/token }}
# NPM_TOKEN={{ op://Development/npm/token }}

# Cloud Providers (if needed for AI workloads)
# AZURE_OPENAI_API_KEY={{ op://Cloud/Azure OpenAI/credential }}
# AWS_ACCESS_KEY_ID={{ op://Cloud/AWS/access_key_id }}
# AWS_SECRET_ACCESS_KEY={{ op://Cloud/AWS/secret_access_key }}

# Add your custom keys below...
