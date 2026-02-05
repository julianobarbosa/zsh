#!/bin/bash

# macOS Disk Cleanup Script
# Description: Interactive disk cleanup utility with multiple safety levels
# Usage: ./cleanup-disk.sh [--dry-run] [--auto] [--level=1|2|3] [--min-size=N] [--quiet]

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly NC='\033[0m' # No Color

# Size thresholds for color warnings (in KB)
readonly SIZE_WARN_KB=1048576    # 1 GB
readonly SIZE_CRIT_KB=5242880    # 5 GB

# Global variables
DRY_RUN=false
AUTO_MODE=false
QUIET_MODE=false
CLEANUP_LEVEL=0
MIN_SIZE_KB=0
TOTAL_SAVED=0
LOGFILE="/tmp/disk-cleanup-$(date +%Y%m%d-%H%M%S).log"

# Cleanup handler for graceful exit
cleanup_on_exit() {
    local exit_code=$?
    if [[ "${TOTAL_SAVED}" -gt 0 ]]; then
        log_info "Session ended. Total freed: $(kb_to_human "${TOTAL_SAVED}")"
    fi
    exit "${exit_code}"
}
trap cleanup_on_exit EXIT

# Parse command line arguments
parse_args() {
    for arg in "$@"; do
        case "${arg}" in
            --dry-run)
                DRY_RUN=true
                ;;
            --auto)
                AUTO_MODE=true
                ;;
            --quiet|-q)
                QUIET_MODE=true
                ;;
            --level=*)
                CLEANUP_LEVEL="${arg#*=}"
                ;;
            --min-size=*)
                MIN_SIZE_KB=$(( ${arg#*=} * 1024 ))  # Convert MB to KB
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: ${arg}"
                show_help
                exit 1
                ;;
        esac
    done
}

# Show help
show_help() {
    cat << 'EOF'
macOS Disk Cleanup Script

Usage: ./cleanup-disk.sh [OPTIONS]

Options:
    --dry-run           Show what would be deleted without deleting
    --auto              Run without prompts (uses --level)
    --level=N           Cleanup level (1=safe, 2=moderate, 3=aggressive)
    --min-size=N        Only clean caches larger than N MB (default: 0)
    --quiet, -q         Reduce output verbosity
    --help, -h          Show this help message

Cleanup Levels:
    Level 1 (Safe):         NPM, Bun, pnpm, Homebrew, temp files, trash, pre-commit, user logs
    Level 2 (Moderate):     Level 1 + Python (uv/pip/__pycache__), Docker, browsers, Cargo, Go, Gradle, Maven, CocoaPods
    Level 3 (Aggressive):   Level 2 + Huggingface, Playwright, Xcode, iOS DeviceSupport, Android SDK

Examples:
    ./cleanup-disk.sh                       # Interactive mode
    ./cleanup-disk.sh --dry-run             # See what would be cleaned
    ./cleanup-disk.sh --auto --level=1      # Auto run level 1 cleanup
    ./cleanup-disk.sh --auto --level=2      # Auto run level 2 cleanup
    ./cleanup-disk.sh --min-size=100        # Only clean caches > 100 MB

EOF
}

# Logging functions
log() {
    echo -e "$1" | tee -a "${LOGFILE}"
}

log_quiet() {
    # Only log to file in quiet mode
    echo -e "$1" >> "${LOGFILE}"
}

log_info() {
    if [[ "${QUIET_MODE}" == "false" ]]; then
        log "${BLUE}[INFO]${NC} $1"
    else
        log_quiet "[INFO] $1"
    fi
}

log_success() {
    # Always show success messages
    log "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    log "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    log "${RED}[ERROR]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" &>/dev/null
}

# Get directory size in KB (returns 0 if path doesn't exist)
get_size() {
    local path="$1"
    if [[ -e "${path}" ]]; then
        du -sk "${path}" 2>/dev/null | awk '{print $1}' || echo "0"
    else
        echo "0"
    fi
}

# Get size with color based on thresholds
get_size_colored() {
    local kb="$1"
    local human
    human=$(kb_to_human "${kb}")

    if [[ "${kb}" -ge "${SIZE_CRIT_KB}" ]]; then
        echo -e "${RED}${human}${NC}"
    elif [[ "${kb}" -ge "${SIZE_WARN_KB}" ]]; then
        echo -e "${YELLOW}${human}${NC}"
    else
        echo "${human}"
    fi
}

# Convert KB to human readable
kb_to_human() {
    local kb="$1"
    if [[ "${kb}" -ge 1048576 ]]; then
        awk "BEGIN {printf \"%.2f GB\", ${kb}/1048576}"
    elif [[ "${kb}" -ge 1024 ]]; then
        awk "BEGIN {printf \"%.2f MB\", ${kb}/1024}"
    else
        echo "${kb} KB"
    fi
}

# Ask for confirmation
confirm() {
    if [[ "${AUTO_MODE}" == "true" ]]; then
        return 0
    fi

    local prompt="$1"
    read -p "$(echo -e "${YELLOW}${prompt}${NC}") (y/N): " -n 1 -r
    echo
    if [[ "${REPLY}" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Check if size meets minimum threshold
meets_min_size() {
    local size_kb="$1"
    [[ "${size_kb}" -ge "${MIN_SIZE_KB}" ]]
}

# Execute cleanup for a path with rm command
execute_cleanup() {
    local description="$1"
    local path="$2"
    local command="$3"

    if [[ ! -e "${path}" ]]; then
        log_info "${description}: Not found, skipping"
        return 0
    fi

    local before_size
    before_size=$(get_size "${path}")
    local before_colored
    before_colored=$(get_size_colored "${before_size}")

    if [[ "${before_size}" -eq 0 ]]; then
        log_info "${description}: Empty, skipping"
        return 0
    fi

    if ! meets_min_size "${before_size}"; then
        log_info "${description}: ${before_colored} (below min-size threshold, skipping)"
        return 0
    fi

    log_info "${description}: Current size: ${before_colored}"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_warning "${description}: [DRY RUN] Would execute: ${command}"
        return 0
    fi

    if confirm "Clean ${description} ($(kb_to_human "${before_size}"))?"; then
        log_info "${description}: Cleaning..."
        if eval "${command}" >> "${LOGFILE}" 2>&1; then
            local after_size
            after_size=$(get_size "${path}")
            local saved=$((before_size - after_size))
            TOTAL_SAVED=$((TOTAL_SAVED + saved))
            log_success "${description}: Cleaned! Freed: $(kb_to_human "${saved}")"
        else
            log_error "${description}: Cleanup command failed"
            return 1
        fi
    else
        log_info "${description}: Skipped"
    fi
}

# Execute cleanup using a command (e.g., npm cache clean)
# More consistent pattern for tool-based cleanups
execute_command_cleanup() {
    local description="$1"
    local check_path="$2"
    local cleanup_cmd="$3"
    local required_cmd="${4:-}"

    # Check if required command exists
    if [[ -n "${required_cmd}" ]] && ! command_exists "${required_cmd}"; then
        log_info "${description}: ${required_cmd} not installed, skipping"
        return 0
    fi

    if [[ ! -e "${check_path}" ]]; then
        log_info "${description}: Not found, skipping"
        return 0
    fi

    local before_size
    before_size=$(get_size "${check_path}")
    local before_colored
    before_colored=$(get_size_colored "${before_size}")

    if [[ "${before_size}" -eq 0 ]]; then
        log_info "${description}: Empty, skipping"
        return 0
    fi

    if ! meets_min_size "${before_size}"; then
        log_info "${description}: ${before_colored} (below min-size threshold, skipping)"
        return 0
    fi

    log_info "${description}: Current size: ${before_colored}"

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_warning "${description}: [DRY RUN] Would execute: ${cleanup_cmd}"
        return 0
    fi

    if confirm "Clean ${description} ($(kb_to_human "${before_size}"))?"; then
        log_info "${description}: Cleaning..."
        if eval "${cleanup_cmd}" >> "${LOGFILE}" 2>&1; then
            local after_size
            after_size=$(get_size "${check_path}")
            local saved=$((before_size - after_size))
            TOTAL_SAVED=$((TOTAL_SAVED + saved))
            log_success "${description}: Cleaned! Freed: $(kb_to_human "${saved}")"
        else
            log_warning "${description}: Cleanup command returned non-zero (may be normal)"
        fi
    else
        log_info "${description}: Skipped"
    fi
}

# Print size line with optional color
print_cache_size() {
    local name="$1"
    local path="$2"
    local size_kb

    if [[ -d "${path}" ]]; then
        size_kb=$(get_size "${path}")
        if [[ "${size_kb}" -gt 0 ]]; then
            printf "  %-25s %s\n" "${name}:" "$(get_size_colored "${size_kb}")"
            return 0
        fi
    fi
    return 1
}

# Show top space consumers
show_top_space_consumers() {
    log_info "${MAGENTA}Top Space Consumers in Home Directory:${NC}"
    echo

    # Get top directories in home (depth 1)
    log_info "Top-level directories:"
    du -sh "${HOME}"/* "${HOME}"/.[!.]* 2>/dev/null | sort -hr | head -15 | while read -r size path; do
        local name
        name=$(basename "${path}")
        printf "  %-35s %s\n" "${name}" "${size}"
    done
    echo

    # Deep scan for largest directories (can take time)
    if [[ "${QUIET_MODE}" == "false" ]]; then
        log_info "Scanning for largest directories (this may take a moment)..."
        echo
        log_info "Top 20 largest directories:"
        # Use timeout and limit depth to avoid very long scans
        timeout 120 du -sh "${HOME}"/*/* "${HOME}"/.[!.]*/* 2>/dev/null | sort -hr | head -20 | while read -r size path; do
            # Show relative path from home
            local rel_path="${path#"${HOME}"/}"
            printf "  %-50s %s\n" "${rel_path}" "${size}"
        done
        echo
    fi
}

# Analysis phase
run_analysis() {
    log_info "=== Disk Space Analysis ==="
    echo

    log_info "Current Disk Usage:"
    df -h / | grep -v Filesystem
    echo

    if [[ "${QUIET_MODE}" == "true" ]]; then
        return 0
    fi

    # Show top space consumers first
    show_top_space_consumers

    log_info "Analyzing caches..."
    echo

    # Package Manager Caches
    log_info "${MAGENTA}Package Manager Caches:${NC}"
    local pkg_total=0
    local found=false
    # Show NPM subdirectories for better visibility
    for cache_info in \
        "NPM _cacache:${HOME}/.npm/_cacache" \
        "NPM _npx:${HOME}/.npm/_npx" \
        "Bun:${HOME}/.bun/install/cache" \
        "pnpm:${HOME}/.pnpm-store" \
        "Yarn:${HOME}/.yarn" \
        "Homebrew:${HOME}/Library/Caches/Homebrew"; do
        local name="${cache_info%%:*}"
        local path="${cache_info#*:}"
        if print_cache_size "${name}" "${path}"; then
            pkg_total=$((pkg_total + $(get_size "${path}")))
            found=true
        fi
    done
    [[ "${found}" == "false" ]] && echo "  (none found)"
    [[ "${pkg_total}" -gt 0 ]] && echo -e "  ${BLUE}Total: $(get_size_colored "${pkg_total}")${NC}"
    echo

    # Language Runtime Caches
    log_info "${MAGENTA}Language Runtime Caches:${NC}"
    local lang_total=0
    found=false
    for cache_info in \
        "UV (Python):${HOME}/.cache/uv" \
        "Pip:${HOME}/Library/Caches/pip" \
        "Cargo (Rust):${HOME}/.cargo/registry" \
        "Go Modules:${HOME}/go/pkg/mod" \
        "Gradle:${HOME}/.gradle/caches" \
        "Maven:${HOME}/.m2/repository" \
        "CocoaPods:${HOME}/Library/Caches/CocoaPods"; do
        local name="${cache_info%%:*}"
        local path="${cache_info#*:}"
        if print_cache_size "${name}" "${path}"; then
            lang_total=$((lang_total + $(get_size "${path}")))
            found=true
        fi
    done
    # Check __pycache__ directories (quick estimate)
    local pycache_size
    pycache_size=$(timeout 30 find "${HOME}" -name "__pycache__" -type d -prune 2>/dev/null | head -1000 | xargs du -sk 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    if [[ "${pycache_size}" -gt 0 ]]; then
        printf "  %-25s %s\n" "__pycache__:" "$(get_size_colored "${pycache_size}")"
        lang_total=$((lang_total + pycache_size))
        found=true
    fi
    [[ "${found}" == "false" ]] && echo "  (none found)"
    [[ "${lang_total}" -gt 0 ]] && echo -e "  ${BLUE}Total: $(get_size_colored "${lang_total}")${NC}"
    echo

    # Development Tool Caches
    log_info "${MAGENTA}Development Tool Caches:${NC}"
    local dev_total=0
    found=false
    for cache_info in \
        "Huggingface:${HOME}/.cache/huggingface" \
        "Playwright:${HOME}/Library/Caches/ms-playwright" \
        "Pre-commit:${HOME}/.cache/pre-commit" \
        "Trunk:${HOME}/.cache/trunk" \
        "Grype:${HOME}/.cache/grype"; do
        local name="${cache_info%%:*}"
        local path="${cache_info#*:}"
        if print_cache_size "${name}" "${path}"; then
            dev_total=$((dev_total + $(get_size "${path}")))
            found=true
        fi
    done
    [[ "${found}" == "false" ]] && echo "  (none found)"
    [[ "${dev_total}" -gt 0 ]] && echo -e "  ${BLUE}Total: $(get_size_colored "${dev_total}")${NC}"
    echo

    # Xcode/Apple Development
    log_info "${MAGENTA}Xcode/Apple Development:${NC}"
    local xcode_total=0
    found=false
    for cache_info in \
        "DerivedData:${HOME}/Library/Developer/Xcode/DerivedData" \
        "iOS DeviceSupport:${HOME}/Library/Developer/Xcode/iOS DeviceSupport" \
        "Archives:${HOME}/Library/Developer/Xcode/Archives"; do
        local name="${cache_info%%:*}"
        local path="${cache_info#*:}"
        if print_cache_size "${name}" "${path}"; then
            xcode_total=$((xcode_total + $(get_size "${path}")))
            found=true
        fi
    done
    [[ "${found}" == "false" ]] && echo "  (none found)"
    [[ "${xcode_total}" -gt 0 ]] && echo -e "  ${BLUE}Total: $(get_size_colored "${xcode_total}")${NC}"
    echo

    # Browser Caches
    log_info "${MAGENTA}Browser Caches:${NC}"
    local browser_total=0
    found=false
    for cache_info in \
        "Arc:${HOME}/Library/Caches/Arc" \
        "Chrome:${HOME}/Library/Caches/Google/Chrome" \
        "Edge:${HOME}/Library/Caches/Microsoft Edge" \
        "Safari:${HOME}/Library/Caches/com.apple.Safari"; do
        local name="${cache_info%%:*}"
        local path="${cache_info#*:}"
        if print_cache_size "${name}" "${path}"; then
            browser_total=$((browser_total + $(get_size "${path}")))
            found=true
        fi
    done
    [[ "${found}" == "false" ]] && echo "  (none found)"
    [[ "${browser_total}" -gt 0 ]] && echo -e "  ${BLUE}Total: $(get_size_colored "${browser_total}")${NC}"
    echo

    # System Caches
    log_info "${MAGENTA}System:${NC}"
    local sys_total=0
    found=false
    for cache_info in \
        "Trash:${HOME}/.Trash" \
        "Temp Files:${HOME}/.cache/tmp" \
        "User Logs:${HOME}/Library/Logs"; do
        local name="${cache_info%%:*}"
        local path="${cache_info#*:}"
        if print_cache_size "${name}" "${path}"; then
            sys_total=$((sys_total + $(get_size "${path}")))
            found=true
        fi
    done
    [[ "${found}" == "false" ]] && echo "  (none found)"
    [[ "${sys_total}" -gt 0 ]] && echo -e "  ${BLUE}Total: $(get_size_colored "${sys_total}")${NC}"
    echo

    # Docker
    if command_exists docker; then
        log_info "${MAGENTA}Docker:${NC}"
        if docker info &>/dev/null; then
            docker system df 2>/dev/null || log_warning "Docker not running"
        else
            echo "  Docker daemon not running"
        fi
        echo
    fi

    # Time Machine
    log_info "${MAGENTA}Time Machine Local Snapshots:${NC}"
    tmutil listlocalsnapshots / 2>/dev/null || echo "  No local snapshots found"
    echo
}

# Level 1: Safe cleanup
cleanup_level_1() {
    log_info "=== Level 1: Safe Cleanup ==="
    echo

    # NPM cache - use rm for complete cleanup (npm cache clean only clears index)
    if command_exists npm; then
        execute_cleanup "NPM Cache" "${HOME}/.npm/_cacache" "rm -rf '${HOME}/.npm/_cacache'"
        execute_cleanup "NPM npx Cache" "${HOME}/.npm/_npx" "rm -rf '${HOME}/.npm/_npx'"
        execute_cleanup "NPM Logs" "${HOME}/.npm/_logs" "rm -rf '${HOME}/.npm/_logs'"
    fi

    # Bun cache
    execute_command_cleanup "Bun Cache" "${HOME}/.bun/install/cache" "bun pm cache rm" "bun"

    # pnpm cache
    execute_command_cleanup "pnpm Cache" "${HOME}/.pnpm-store" "pnpm store prune" "pnpm"

    # Homebrew cache
    execute_command_cleanup "Homebrew Cache" "${HOME}/Library/Caches/Homebrew" "brew cleanup -s" "brew"

    # Temporary files
    execute_cleanup "User Cache Temp" "${HOME}/.cache/tmp" "rm -rf '${HOME}/.cache/tmp/'*"

    # Trash
    execute_cleanup "Trash" "${HOME}/.Trash" "rm -rf '${HOME}/.Trash/'*"

    # Pre-commit cache
    execute_command_cleanup "Pre-commit Cache" "${HOME}/.cache/pre-commit" "pre-commit clean && pre-commit gc" "pre-commit"

    # User logs
    execute_cleanup "User Logs" "${HOME}/Library/Logs" "rm -rf '${HOME}/Library/Logs/'*"
}

# Level 2: Moderate cleanup
cleanup_level_2() {
    cleanup_level_1

    log_info "=== Level 2: Moderate Cleanup ==="
    echo

    # Python caches
    execute_command_cleanup "UV Cache" "${HOME}/.cache/uv" "uv cache clean" "uv"
    execute_command_cleanup "Pip Cache" "${HOME}/Library/Caches/pip" "pip cache purge" "pip"

    # Python __pycache__ directories
    if [[ "${QUIET_MODE}" == "false" ]]; then
        log_info "Finding __pycache__ directories..."
        local pycache_size
        pycache_size=$(timeout 60 find "${HOME}" -name "__pycache__" -type d -prune 2>/dev/null | xargs du -sk 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
        if [[ "${pycache_size}" -gt 0 ]]; then
            local pycache_colored
            pycache_colored=$(get_size_colored "${pycache_size}")
            log_info "__pycache__ directories: ${pycache_colored}"
            if [[ "${DRY_RUN}" == "true" ]]; then
                log_warning "[DRY RUN] Would clean __pycache__ directories"
            elif confirm "Clean __pycache__ directories ($(kb_to_human "${pycache_size}"))?"; then
                log_info "Cleaning __pycache__ directories..."
                local before_size="${pycache_size}"
                find "${HOME}" -name "__pycache__" -type d -prune -exec rm -rf '{}' + 2>/dev/null || true
                TOTAL_SAVED=$((TOTAL_SAVED + before_size))
                log_success "__pycache__: Cleaned! Freed: $(kb_to_human "${before_size}")"
            fi
        else
            log_info "__pycache__: None found or empty"
        fi
    fi

    # Rust cache
    if command_exists cargo; then
        execute_cleanup "Cargo Registry" "${HOME}/.cargo/registry" "rm -rf '${HOME}/.cargo/registry/'*"
        execute_cleanup "Cargo Git" "${HOME}/.cargo/git" "rm -rf '${HOME}/.cargo/git/'*"
    fi

    # Go cache
    execute_command_cleanup "Go Module Cache" "${HOME}/go/pkg/mod" "go clean -modcache" "go"

    # Java caches
    execute_cleanup "Gradle Cache" "${HOME}/.gradle/caches" "rm -rf '${HOME}/.gradle/caches/'*"
    execute_cleanup "Maven Cache" "${HOME}/.m2/repository" "rm -rf '${HOME}/.m2/repository/'*"

    # CocoaPods cache
    execute_command_cleanup "CocoaPods Cache" "${HOME}/Library/Caches/CocoaPods" "pod cache clean --all" "pod"

    # Docker cleanup
    if command_exists docker; then
        if docker info &>/dev/null; then
            local docker_size
            docker_size=$(docker system df --format '{{.Size}}' 2>/dev/null | head -1 || echo "unknown")
            log_info "Docker cleanup available (current usage: ${docker_size})"
            if [[ "${DRY_RUN}" == "true" ]]; then
                log_warning "[DRY RUN] Would clean Docker (unused containers, images, networks)"
            elif confirm "Clean Docker (remove unused containers, images, networks)?"; then
                log_info "Cleaning Docker..."
                if docker system prune -a -f >> "${LOGFILE}" 2>&1; then
                    log_success "Docker cleaned!"
                else
                    log_warning "Docker cleanup failed (may require manual intervention)"
                fi
            fi
        else
            log_info "Docker: Daemon not running, skipping"
        fi
    fi

    # Browser caches
    execute_cleanup "Arc Browser Cache" "${HOME}/Library/Caches/Arc" "rm -rf '${HOME}/Library/Caches/Arc/'*"
    execute_cleanup "Chrome Cache" "${HOME}/Library/Caches/Google/Chrome" "rm -rf '${HOME}/Library/Caches/Google/Chrome/'*"
    execute_cleanup "Edge Cache" "${HOME}/Library/Caches/Microsoft Edge" "rm -rf '${HOME}/Library/Caches/Microsoft Edge/'*"
}

# Level 3: Aggressive cleanup
cleanup_level_3() {
    cleanup_level_2

    log_info "=== Level 3: Aggressive Cleanup ==="
    log_warning "WARNING: This level removes large caches that may take time to rebuild"
    echo

    # ML/AI caches
    log_info "ML/AI Caches (may require re-download):"
    execute_cleanup "Huggingface Cache" "${HOME}/.cache/huggingface" "rm -rf '${HOME}/.cache/huggingface'"

    # Development tool caches
    execute_cleanup "Playwright Browsers" "${HOME}/Library/Caches/ms-playwright" "rm -rf '${HOME}/Library/Caches/ms-playwright'"
    execute_cleanup "Trunk Cache" "${HOME}/.cache/trunk" "rm -rf '${HOME}/.cache/trunk'"
    execute_cleanup "Grype Cache" "${HOME}/.cache/grype" "rm -rf '${HOME}/.cache/grype'"

    # Xcode/Apple development (can be very large)
    log_info "Xcode Caches (may require rebuild):"
    execute_cleanup "Xcode DerivedData" "${HOME}/Library/Developer/Xcode/DerivedData" "rm -rf '${HOME}/Library/Developer/Xcode/DerivedData/'*"
    execute_cleanup "iOS DeviceSupport" "${HOME}/Library/Developer/Xcode/iOS DeviceSupport" "rm -rf '${HOME}/Library/Developer/Xcode/iOS DeviceSupport/'*"
    execute_cleanup "Xcode Archives" "${HOME}/Library/Developer/Xcode/Archives" "rm -rf '${HOME}/Library/Developer/Xcode/Archives/'*"

    # Android SDK cache
    execute_cleanup "Android SDK Cache" "${HOME}/.android/cache" "rm -rf '${HOME}/.android/cache/'*"

    # Node modules (list only - too dangerous to auto-delete)
    # Skip in auto mode as find can take very long
    if [[ "${QUIET_MODE}" == "false" && "${AUTO_MODE}" == "false" ]]; then
        log_info "Finding node_modules directories (this may take a moment)..."
        local node_modules_count
        # Use timeout to prevent hanging on large filesystems
        node_modules_count=$(timeout 30 find "${HOME}" -name "node_modules" -type d -prune 2>/dev/null | wc -l | tr -d ' ' || echo "0")
        if [[ "${node_modules_count}" -gt 0 ]]; then
            log_warning "Found ${node_modules_count} node_modules directories"
            log_info "To remove them manually, run:"
            log_info "  find ~ -name \"node_modules\" -type d -prune 2>/dev/null"
            log_info "  find ~ -name \"node_modules\" -type d -prune -exec rm -rf '{}' +"
        fi
    fi
}

# Main cleanup function
run_cleanup() {
    case "${CLEANUP_LEVEL}" in
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
            log_error "Invalid cleanup level: ${CLEANUP_LEVEL}"
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
    echo "  1) Safe        - NPM, Bun, pnpm, Homebrew, temp files, trash, logs"
    echo "  2) Moderate    - Level 1 + Python, Rust, Go, Java, Docker, browsers"
    echo "  3) Aggressive  - Level 2 + Huggingface, Xcode, Playwright, etc."
    echo "  4) Custom      - Choose individual items"
    echo "  0) Exit"
    echo

    local choice
    read -p "Enter choice [0-4]: " choice

    case "${choice}" in
        1|2|3)
            CLEANUP_LEVEL="${choice}"
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

    # Package managers - NPM uses rm for complete cleanup
    if command_exists npm; then
        execute_cleanup "NPM Cache" "${HOME}/.npm/_cacache" "rm -rf '${HOME}/.npm/_cacache'"
        execute_cleanup "NPM npx Cache" "${HOME}/.npm/_npx" "rm -rf '${HOME}/.npm/_npx'"
        execute_cleanup "NPM Logs" "${HOME}/.npm/_logs" "rm -rf '${HOME}/.npm/_logs'"
    fi
    execute_command_cleanup "Bun Cache" "${HOME}/.bun/install/cache" "bun pm cache rm" "bun"
    execute_command_cleanup "pnpm Cache" "${HOME}/.pnpm-store" "pnpm store prune" "pnpm"
    execute_command_cleanup "Homebrew Cache" "${HOME}/Library/Caches/Homebrew" "brew cleanup -s" "brew"

    # System
    execute_cleanup "Temp Files" "${HOME}/.cache/tmp" "rm -rf '${HOME}/.cache/tmp/'*"
    execute_cleanup "Trash" "${HOME}/.Trash" "rm -rf '${HOME}/.Trash/'*"
    execute_cleanup "User Logs" "${HOME}/Library/Logs" "rm -rf '${HOME}/Library/Logs/'*"

    # Python
    execute_command_cleanup "UV Cache" "${HOME}/.cache/uv" "uv cache clean" "uv"
    execute_command_cleanup "Pip Cache" "${HOME}/Library/Caches/pip" "pip cache purge" "pip"

    # Other languages
    if command_exists cargo; then
        execute_cleanup "Cargo Registry" "${HOME}/.cargo/registry" "rm -rf '${HOME}/.cargo/registry/'*"
        execute_cleanup "Cargo Git" "${HOME}/.cargo/git" "rm -rf '${HOME}/.cargo/git/'*"
    fi
    execute_command_cleanup "Go Module Cache" "${HOME}/go/pkg/mod" "go clean -modcache" "go"
    execute_cleanup "Gradle Cache" "${HOME}/.gradle/caches" "rm -rf '${HOME}/.gradle/caches/'*"
    execute_cleanup "Maven Cache" "${HOME}/.m2/repository" "rm -rf '${HOME}/.m2/repository/'*"

    # Docker
    if command_exists docker && docker info &>/dev/null; then
        if confirm "Clean Docker (remove unused containers, images)?"; then
            if docker system prune -a -f >> "${LOGFILE}" 2>&1; then
                log_success "Docker cleaned!"
            else
                log_warning "Docker cleanup failed"
            fi
        fi
    fi

    # ML/AI
    execute_cleanup "Huggingface Cache" "${HOME}/.cache/huggingface" "rm -rf '${HOME}/.cache/huggingface'"

    # Xcode
    execute_cleanup "Xcode DerivedData" "${HOME}/Library/Developer/Xcode/DerivedData" "rm -rf '${HOME}/Library/Developer/Xcode/DerivedData/'*"
}

# Summary
show_summary() {
    echo
    log_info "=== Cleanup Summary ==="
    log_success "Total Space Freed: $(kb_to_human "${TOTAL_SAVED}")"
    log_info "Log file: ${LOGFILE}"
    echo

    log_info "Current Disk Usage:"
    df -h / | grep -v Filesystem
    echo

    if [[ "${DRY_RUN}" == "true" ]]; then
        log_warning "This was a dry run. No files were actually deleted."
        log_info "Run without --dry-run to perform actual cleanup"
    fi

    if [[ "${MIN_SIZE_KB}" -gt 0 ]]; then
        log_info "Note: Only caches >= $(kb_to_human "${MIN_SIZE_KB}") were considered"
    fi
}

# Main execution
main() {
    parse_args "$@"

    log_info "Starting disk cleanup - $(date)"
    log_info "Log file: ${LOGFILE}"
    if [[ "${MIN_SIZE_KB}" -gt 0 ]]; then
        log_info "Minimum size threshold: $(kb_to_human "${MIN_SIZE_KB}")"
    fi
    echo

    if [[ "${AUTO_MODE}" == "true" ]]; then
        if [[ "${CLEANUP_LEVEL}" -eq 0 ]]; then
            log_error "Auto mode requires --level=N"
            show_help
            exit 1
        fi
        log_info "Running in auto mode with level ${CLEANUP_LEVEL}"
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
