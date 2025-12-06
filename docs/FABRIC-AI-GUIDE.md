# Fabric AI Framework Guide

Fabric is an open-source framework for augmenting humans using AI. It organizes AI prompts (called Patterns) into reusable, task-specific commands.

## Installation

### macOS (Homebrew) - Recommended

```bash
brew install fabric-ai
```

> **Note:** When installed via Homebrew, the command is `fabric-ai`. Add an alias to use `fabric`:

```bash
# Add to ~/.zshrc
alias fabric='fabric-ai'
```

### One-Line Install

```bash
curl -fsSL https://raw.githubusercontent.com/danielmiessler/fabric/main/scripts/installer/install.sh | bash
```

### From Source (requires Go)

```bash
go install github.com/danielmiessler/fabric/cmd/fabric@latest
```

## Initial Setup

After installation, run the setup wizard:

```bash
fabric --setup
```

This will:
- Create `~/.config/fabric/` directory structure
- Download available patterns to `~/.config/fabric/patterns/`
- Configure API keys (OpenAI, Claude, Gemini, etc.)

## Add Aliases for All Patterns

The power of Fabric is using patterns as direct commands. Instead of:

```bash
fabric --pattern summarize
```

You can simply run:

```bash
summarize
```

### Zsh Configuration

Add the following to your `~/.zshrc`:

```bash
#==============================================================================
# Fabric AI Pattern Aliases
#==============================================================================

# Optional: Add a prefix to all pattern aliases (e.g., "f-summarize")
# export FABRIC_ALIAS_PREFIX="f-"

# Dynamically create aliases for all Fabric patterns
if [ -d "$HOME/.config/fabric/patterns" ]; then
    for pattern_file in $HOME/.config/fabric/patterns/*; do
        if [ -d "$pattern_file" ]; then
            pattern_name="$(basename "$pattern_file")"
            alias_name="${FABRIC_ALIAS_PREFIX:-}${pattern_name}"
            alias "$alias_name"="fabric --pattern $pattern_name"
        fi
    done
fi
```

### Bash Configuration

Add the following to your `~/.bashrc`:

```bash
#==============================================================================
# Fabric AI Pattern Aliases
#==============================================================================

# Optional: Add a prefix to all pattern aliases
# export FABRIC_ALIAS_PREFIX="f-"

# Dynamically create aliases for all Fabric patterns
if [ -d "$HOME/.config/fabric/patterns" ]; then
    for pattern_file in "$HOME/.config/fabric/patterns"/*; do
        if [ -d "$pattern_file" ]; then
            pattern_name="$(basename "$pattern_file")"
            alias_name="${FABRIC_ALIAS_PREFIX:-}${pattern_name}"
            alias "$alias_name"="fabric --pattern $pattern_name"
        fi
    done
fi
```

### Reload Your Shell

```bash
source ~/.zshrc  # or ~/.bashrc
```

## YouTube Helper Function

Add this function to easily extract YouTube transcripts:

```bash
#==============================================================================
# Fabric YouTube Helper
#==============================================================================

yt() {
    if [ "$#" -eq 0 ] || [ "$#" -gt 2 ]; then
        echo "Usage: yt [-t | --timestamps] <youtube-link>"
        echo ""
        echo "Options:"
        echo "  -t, --timestamps    Include timestamps in transcript"
        echo ""
        echo "Examples:"
        echo "  yt https://www.youtube.com/watch?v=VIDEO_ID"
        echo "  yt -t https://www.youtube.com/watch?v=VIDEO_ID"
        return 1
    fi

    local transcript_flag="--transcript"

    if [ "$1" = "-t" ] || [ "$1" = "--timestamps" ]; then
        transcript_flag="--transcript-with-timestamps"
        shift
    fi

    local video_link="$1"
    fabric -y "$video_link" $transcript_flag
}
```

## Usage Examples

### Basic Pattern Usage

```bash
# Summarize text from clipboard
pbpaste | summarize

# Summarize a file
cat article.txt | summarize

# Extract wisdom from a YouTube video
yt https://www.youtube.com/watch?v=VIDEO_ID | extract_wisdom

# Analyze code
cat script.py | analyze_code

# Create a blog post outline
echo "Topic: AI in healthcare" | create_outline
```

### With Specific Models

```bash
# Use Claude
echo "Hello" | summarize --model claude-3-5-sonnet-20241022

# Use GPT-4
echo "Hello" | summarize --model gpt-4o

# Use Gemini
echo "Hello" | summarize --model gemini-1.5-pro
```

### Piping Patterns Together

```bash
# Extract transcript, then summarize
yt https://www.youtube.com/watch?v=VIDEO_ID | summarize

# Summarize, then create tweet thread
cat article.txt | summarize | create_tweet_thread
```

### Save Output to File

```bash
# Save summary to file
cat article.txt | summarize > summary.md

# Copy to clipboard (macOS)
cat article.txt | summarize | pbcopy
```

## Common Patterns

| Pattern | Description |
|---------|-------------|
| `summarize` | Create a concise summary |
| `extract_wisdom` | Extract key insights and quotes |
| `analyze_code` | Review and analyze code |
| `explain_code` | Explain what code does |
| `improve_writing` | Enhance text quality |
| `create_outline` | Generate content outline |
| `extract_main_idea` | Get the core concept |
| `create_tweet_thread` | Convert to Twitter thread |
| `write_essay` | Generate essay from topic |
| `analyze_claims` | Fact-check and analyze claims |

### List All Available Patterns

```bash
fabric --list
# or
ls ~/.config/fabric/patterns/
```

## Update Patterns

To get the latest patterns:

```bash
fabric --update
```

## Custom Patterns

Create your own patterns in `~/.config/fabric/patterns/`:

```bash
mkdir -p ~/.config/fabric/patterns/my_custom_pattern
```

Create a `system.md` file with your prompt:

```bash
cat > ~/.config/fabric/patterns/my_custom_pattern/system.md << 'EOF'
# IDENTITY and PURPOSE

You are an expert at [specific task].

# STEPS

1. First, analyze the input
2. Then, process it according to [criteria]
3. Finally, output the result

# OUTPUT INSTRUCTIONS

- Output in markdown format
- Be concise and clear

# INPUT

INPUT:
EOF
```

After adding custom patterns, reload your shell to create the alias.

## Configuration

### Config File Location

```
~/.config/fabric/
├── .env                 # API keys and settings
├── patterns/            # All patterns (built-in + custom)
│   ├── summarize/
│   ├── extract_wisdom/
│   └── ...
└── contexts/            # Custom contexts
```

### Environment Variables

```bash
# API Keys (set during --setup or manually in ~/.config/fabric/.env)
export OPENAI_API_KEY="sk-..."
export ANTHROPIC_API_KEY="sk-ant-..."
export GOOGLE_API_KEY="..."

# Default model
export DEFAULT_MODEL="claude-3-5-sonnet-20241022"

# Pattern alias prefix (optional)
export FABRIC_ALIAS_PREFIX=""
```

## Troubleshooting

### Aliases Not Working

1. Ensure patterns are downloaded:
   ```bash
   ls ~/.config/fabric/patterns/
   ```

2. If empty, run:
   ```bash
   fabric --update
   ```

3. Reload shell:
   ```bash
   source ~/.zshrc
   ```

### API Key Errors

Re-run setup:
```bash
fabric --setup
```

### Command Not Found (Homebrew)

Add the alias:
```bash
echo "alias fabric='fabric-ai'" >> ~/.zshrc
source ~/.zshrc
```

## References

- [Fabric GitHub Repository](https://github.com/danielmiessler/fabric)
- [Pattern Library](https://github.com/danielmiessler/fabric/tree/main/patterns)
- [Fabric Documentation](https://github.com/danielmiessler/fabric/blob/main/README.md)
