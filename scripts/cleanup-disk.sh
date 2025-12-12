#!/bin/bash

# macOS Disk Cleanup Script
# Description: Interactive disk cleanup utility with multiple safety levels
# Usage: ./cleanup-disk.sh [--dry-run] [--auto] [--level=1|2|3]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
DRY_RUN=false
AUTO_MODE=false
CLEANUP_LEVEL=0
TOTAL_SAVED=0
LOGFILE="/tmp/disk-cleanup-$(date +%Y%m%d-%H%M%S).log"

# Parse command line arguments
parse_args() {
    for arg in "$@"; do
        case $arg in
            --dry-run)
                DRY_RUN=true
                ;;
            --auto)
                AUTO_MODE=true
                ;;
            --level=*)
                CLEANUP_LEVEL="${arg#*=}"
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
        esac
    done
}

# Show help
show_help() {
    cat << EOF
macOS Disk Cleanup Script

Usage: ./cleanup-disk.sh [OPTIONS]

Options:
    --dry-run           Show what would be deleted without deleting
    --auto              Run without prompts (uses --level)
    --level=N           Cleanup level (1=safe, 2=moderate, 3=aggressive)
    --help, -h          Show this help message

Cleanup Levels:
    Level 1 (Safe):         NPM, Homebrew, temp files, trash
    Level 2 (Moderate):     Level 1 + Python caches, Docker, browsers
    Level 3 (Aggressive):   Level 2 + Huggingface, Playwright, node_modules

Examples:
    ./cleanup-disk.sh                    # Interactive mode
    ./cleanup-disk.sh --dry-run          # See what would be cleaned
    ./cleanup-disk.sh --auto --level=1   # Auto run level 1 cleanup
    ./cleanup-disk.sh --auto --level=2   # Auto run level 2 cleanup

EOF
}

# Logging functions
log() {
    echo -e "$1" | tee -a "$LOGFILE"
}

log_info() {
    log "${BLUE}[INFO]${NC} $1"
}

log_success() {
    log "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    log "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    log "${RED}[ERROR]${NC} $1"
}

# Get directory size in bytes
get_size() {
    local path="$1"
    if [ -e "$path" ]; then
        du -sk "$path" 2>/dev/null | awk '{print $1}'
    else
        echo "0"
    fi
}

# Convert KB to human readable
kb_to_human() {
    local kb=$1
    if [ "$kb" -ge 1048576 ]; then
        echo "$(echo "scale=2; $kb/1048576" | bc) GB"
    elif [ "$kb" -ge 1024 ]; then
        echo "$(echo "scale=2; $kb/1024" | bc) MB"
    else
        echo "${kb} KB"
    fi
}

# Ask for confirmation
confirm() {
    if [ "$AUTO_MODE" = true ]; then
        return 0
    fi

    local prompt="$1"
    read -p "$(echo -e ${YELLOW}${prompt}${NC}) (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Execute cleanup command
execute_cleanup() {
    local description="$1"
    local path="$2"
    local command="$3"

    if [ ! -e "$path" ]; then
        log_info "$description: Not found, skipping"
        return
    fi

    local before_size=$(get_size "$path")
    local before_human=$(kb_to_human "$before_size")

    log_info "$description: Current size: $before_human"

    if [ "$before_size" -eq 0 ]; then
        log_info "$description: Empty, skipping"
        return
    fi

    if [ "$DRY_RUN" = true ]; then
        log_warning "$description: [DRY RUN] Would execute: $command"
        return
    fi

    if confirm "Clean $description ($before_human)?"; then
        log_info "$description: Cleaning..."
        eval "$command" >> "$LOGFILE" 2>&1

        local after_size=$(get_size "$path")
        local saved=$((before_size - after_size))
        TOTAL_SAVED=$((TOTAL_SAVED + saved))

        local saved_human=$(kb_to_human "$saved")
        log_success "$description: Cleaned! Freed: $saved_human"
    else
        log_info "$description: Skipped"
    fi
}

# Analysis phase
run_analysis() {
    log_info "=== Disk Space Analysis ==="
    echo

    log_info "Current Disk Usage:"
    df -h / | grep -v Filesystem
    echo

    log_info "Analyzing caches..."
    echo

    # User cache
    log_info "User Cache (~/.cache):"
    du -sh ~/.cache/* 2>/dev/null | sort -hr | head -10 || log_warning "No user cache found"
    echo

    # System cache
    log_info "System Cache (~/Library/Caches) - Top 10:"
    du -sh ~/Library/Caches/* 2>/dev/null | sort -hr | head -10 || log_warning "No system cache found"
    echo

    # Development caches
    log_info "Development Caches:"
    [ -d ~/.npm ] && echo "NPM: $(du -sh ~/.npm 2>/dev/null | awk '{print $1}')"
    [ -d ~/.yarn ] && echo "Yarn: $(du -sh ~/.yarn 2>/dev/null | awk '{print $1}')"
    [ -d ~/Library/Caches/Homebrew ] && echo "Homebrew: $(du -sh ~/Library/Caches/Homebrew 2>/dev/null | awk '{print $1}')"
    echo

    # Docker
    if command -v docker &> /dev/null; then
        log_info "Docker Usage:"
        docker system df 2>/dev/null || log_warning "Docker not running"
        echo
    fi

    # Time Machine
    log_info "Time Machine Local Snapshots:"
    tmutil listlocalsnapshots / 2>/dev/null || log_info "No local snapshots found"
    echo
}

# Level 1: Safe cleanup
cleanup_level_1() {
    log_info "=== Level 1: Safe Cleanup ==="
    echo

    # NPM cache
    if command -v npm &> /dev/null; then
        if [ -d ~/.npm ]; then
            local size=$(get_size ~/.npm)
            log_info "NPM Cache: $(kb_to_human $size)"
            if [ "$DRY_RUN" = true ]; then
                log_warning "[DRY RUN] Would clean NPM cache"
            elif confirm "Clean NPM cache ($(kb_to_human $size))?"; then
                log_info "Cleaning NPM cache..."
                npm cache clean --force >> "$LOGFILE" 2>&1
                local saved=$((size - $(get_size ~/.npm)))
                TOTAL_SAVED=$((TOTAL_SAVED + saved))
                log_success "NPM cache cleaned! Freed: $(kb_to_human $saved)"
            fi
        fi
    fi

    # Homebrew cache
    if command -v brew &> /dev/null; then
        if [ -d ~/Library/Caches/Homebrew ]; then
            local size=$(get_size ~/Library/Caches/Homebrew)
            log_info "Homebrew Cache: $(kb_to_human $size)"
            if [ "$DRY_RUN" = true ]; then
                log_warning "[DRY RUN] Would clean Homebrew cache"
            elif confirm "Clean Homebrew cache ($(kb_to_human $size))?"; then
                log_info "Cleaning Homebrew cache..."
                brew cleanup -s >> "$LOGFILE" 2>&1
                local saved=$((size - $(get_size ~/Library/Caches/Homebrew)))
                TOTAL_SAVED=$((TOTAL_SAVED + saved))
                log_success "Homebrew cache cleaned! Freed: $(kb_to_human $saved)"
            fi
        fi
    fi

    # Temporary files
    execute_cleanup "User Cache Temp" "$HOME/.cache/tmp" "rm -rf ~/.cache/tmp/*"

    # Trash
    execute_cleanup "Trash" "$HOME/.Trash" "rm -rf ~/.Trash/*"

    # Pre-commit cache
    if command -v pre-commit &> /dev/null; then
        if [ -d ~/.cache/pre-commit ]; then
            local size=$(get_size ~/.cache/pre-commit)
            log_info "Pre-commit Cache: $(kb_to_human $size)"
            if [ "$DRY_RUN" = true ]; then
                log_warning "[DRY RUN] Would clean pre-commit cache"
            elif confirm "Clean pre-commit cache ($(kb_to_human $size))?"; then
                log_info "Cleaning pre-commit cache..."
                pre-commit clean >> "$LOGFILE" 2>&1
                pre-commit gc >> "$LOGFILE" 2>&1
                local saved=$((size - $(get_size ~/.cache/pre-commit)))
                TOTAL_SAVED=$((TOTAL_SAVED + saved))
                log_success "Pre-commit cache cleaned! Freed: $(kb_to_human $saved)"
            fi
        fi
    fi
}

# Level 2: Moderate cleanup
cleanup_level_2() {
    cleanup_level_1

    log_info "=== Level 2: Moderate Cleanup ==="
    echo

    # UV cache
    if command -v uv &> /dev/null; then
        if [ -d ~/.cache/uv ]; then
            local size=$(get_size ~/.cache/uv)
            log_info "UV Cache: $(kb_to_human $size)"
            if [ "$DRY_RUN" = true ]; then
                log_warning "[DRY RUN] Would clean UV cache"
            elif confirm "Clean UV cache ($(kb_to_human $size))?"; then
                log_info "Cleaning UV cache..."
                uv cache clean >> "$LOGFILE" 2>&1
                local saved=$((size - $(get_size ~/.cache/uv)))
                TOTAL_SAVED=$((TOTAL_SAVED + saved))
                log_success "UV cache cleaned! Freed: $(kb_to_human $saved)"
            fi
        fi
    fi

    # Pip cache
    if command -v pip &> /dev/null; then
        if [ -d ~/Library/Caches/pip ]; then
            local size=$(get_size ~/Library/Caches/pip)
            log_info "Pip Cache: $(kb_to_human $size)"
            if [ "$DRY_RUN" = true ]; then
                log_warning "[DRY RUN] Would clean pip cache"
            elif confirm "Clean pip cache ($(kb_to_human $size))?"; then
                log_info "Cleaning pip cache..."
                pip cache purge >> "$LOGFILE" 2>&1
                local saved=$((size - $(get_size ~/Library/Caches/pip)))
                TOTAL_SAVED=$((TOTAL_SAVED + saved))
                log_success "Pip cache cleaned! Freed: $(kb_to_human $saved)"
            fi
        fi
    fi

    # Docker cleanup
    if command -v docker &> /dev/null; then
        if docker info &> /dev/null; then
            log_info "Docker cleanup available"
            if [ "$DRY_RUN" = true ]; then
                log_warning "[DRY RUN] Would clean Docker (unused containers, images, networks)"
            elif confirm "Clean Docker (remove unused containers, images, networks)?"; then
                log_info "Cleaning Docker..."
                docker system prune -a -f >> "$LOGFILE" 2>&1
                log_success "Docker cleaned!"
            fi
        fi
    fi

    # Browser caches
    execute_cleanup "Arc Browser Cache" "$HOME/Library/Caches/Arc" "rm -rf ~/Library/Caches/Arc/*"
    execute_cleanup "Chrome Cache" "$HOME/Library/Caches/Google/Chrome" "rm -rf ~/Library/Caches/Google/Chrome/*"
    execute_cleanup "Edge Cache" "$HOME/Library/Caches/Microsoft Edge" "rm -rf ~/Library/Caches/Microsoft\ Edge/*"
}

# Level 3: Aggressive cleanup
cleanup_level_3() {
    cleanup_level_2

    log_info "=== Level 3: Aggressive Cleanup ==="
    log_warning "WARNING: This level removes large caches that may take time to rebuild"
    echo

    # Huggingface cache
    if [ -d ~/.cache/huggingface ]; then
        local size=$(get_size ~/.cache/huggingface)
        log_info "Huggingface Cache: $(kb_to_human $size)"
        log_warning "This contains ML models that may take time to re-download"
        if [ "$DRY_RUN" = true ]; then
            log_warning "[DRY RUN] Would remove Huggingface cache"
        elif confirm "Remove Huggingface cache ($(kb_to_human $size))?"; then
            log_info "Removing Huggingface cache..."
            rm -rf ~/.cache/huggingface >> "$LOGFILE" 2>&1
            TOTAL_SAVED=$((TOTAL_SAVED + size))
            log_success "Huggingface cache removed! Freed: $(kb_to_human $size)"
        fi
    fi

    # Playwright browsers
    execute_cleanup "Playwright Browsers" "$HOME/Library/Caches/ms-playwright" "rm -rf ~/Library/Caches/ms-playwright"

    # Trunk cache
    execute_cleanup "Trunk Cache" "$HOME/.cache/trunk" "rm -rf ~/.cache/trunk"

    # Grype cache
    execute_cleanup "Grype Cache" "$HOME/.cache/grype" "rm -rf ~/.cache/grype"

    # Node modules (list only - too dangerous to auto-delete)
    log_info "Finding node_modules directories..."
    local node_modules_count=$(find ~ -name "node_modules" -type d -prune 2>/dev/null | wc -l | tr -d ' ')
    if [ "$node_modules_count" -gt 0 ]; then
        log_warning "Found $node_modules_count node_modules directories"
        log_info "To remove them manually, run:"
        log_info "  find ~ -name \"node_modules\" -type d -prune 2>/dev/null"
        log_info "  find ~ -name \"node_modules\" -type d -prune -exec rm -rf '{}' +"
    fi
}

# Main cleanup function
run_cleanup() {
    case $CLEANUP_LEVEL in
        1)
            cleanup_level_1
            ;;
        2)
            cleanup_level_2
            ;;
        3)
            cleanup_level_3
            ;;
        *)
            log_error "Invalid cleanup level: $CLEANUP_LEVEL"
            exit 1
            ;;
    esac
}

# Interactive mode
interactive_mode() {
    clear
    cat << "EOF"
╔════════════════════════════════════════════════════════════╗
║           macOS Disk Cleanup Utility                       ║
╚════════════════════════════════════════════════════════════╝
EOF
    echo

    run_analysis

    echo
    log_info "Select cleanup level:"
    echo "  1) Safe        - NPM, Homebrew, temp files, trash"
    echo "  2) Moderate    - Level 1 + Python caches, Docker, browsers"
    echo "  3) Aggressive  - Level 2 + Huggingface, Playwright, etc."
    echo "  4) Custom      - Choose individual items"
    echo "  0) Exit"
    echo

    read -p "Enter choice [0-4]: " choice

    case $choice in
        1|2|3)
            CLEANUP_LEVEL=$choice
            run_cleanup
            ;;
        4)
            custom_cleanup
            ;;
        0)
            log_info "Exiting..."
            exit 0
            ;;
        *)
            log_error "Invalid choice"
            exit 1
            ;;
    esac
}

# Custom cleanup menu
custom_cleanup() {
    log_info "=== Custom Cleanup ==="
    echo

    # NPM
    if [ -d ~/.npm ]; then
        execute_cleanup "NPM Cache" "$HOME/.npm" "npm cache clean --force"
    fi

    # Homebrew
    if [ -d ~/Library/Caches/Homebrew ]; then
        execute_cleanup "Homebrew Cache" "$HOME/Library/Caches/Homebrew" "brew cleanup -s"
    fi

    # Temp
    execute_cleanup "Temp Files" "$HOME/.cache/tmp" "rm -rf ~/.cache/tmp/*"

    # Trash
    execute_cleanup "Trash" "$HOME/.Trash" "rm -rf ~/.Trash/*"

    # UV
    if [ -d ~/.cache/uv ]; then
        execute_cleanup "UV Cache" "$HOME/.cache/uv" "uv cache clean"
    fi

    # Pip
    if [ -d ~/Library/Caches/pip ]; then
        execute_cleanup "Pip Cache" "$HOME/Library/Caches/pip" "pip cache purge"
    fi

    # Docker
    if command -v docker &> /dev/null && docker info &> /dev/null; then
        if confirm "Clean Docker (remove unused containers, images)?"; then
            docker system prune -a -f >> "$LOGFILE" 2>&1
            log_success "Docker cleaned!"
        fi
    fi

    # Huggingface
    if [ -d ~/.cache/huggingface ]; then
        execute_cleanup "Huggingface Cache" "$HOME/.cache/huggingface" "rm -rf ~/.cache/huggingface"
    fi
}

# Summary
show_summary() {
    echo
    log_info "=== Cleanup Summary ==="
    log_success "Total Space Freed: $(kb_to_human $TOTAL_SAVED)"
    log_info "Log file: $LOGFILE"
    echo

    log_info "Current Disk Usage:"
    df -h / | grep -v Filesystem
    echo

    if [ "$DRY_RUN" = true ]; then
        log_warning "This was a dry run. No files were actually deleted."
        log_info "Run without --dry-run to perform actual cleanup"
    fi
}

# Main execution
main() {
    parse_args "$@"

    log_info "Starting disk cleanup - $(date)"
    log_info "Log file: $LOGFILE"
    echo

    if [ "$AUTO_MODE" = true ]; then
        if [ "$CLEANUP_LEVEL" -eq 0 ]; then
            log_error "Auto mode requires --level=N"
            show_help
            exit 1
        fi
        log_info "Running in auto mode with level $CLEANUP_LEVEL"
        run_analysis
        run_cleanup
    else
        interactive_mode
    fi

    show_summary

    log_info "Cleanup completed - $(date)"
}

# Run main
main "$@"
