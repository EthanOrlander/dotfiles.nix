#!/usr/bin/env bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Worktree base directory
WORKTREE_BASE="$HOME/code/lims-worktrees"

# Cache directory for dependencies
CACHE_DIR="$HOME/.cache/lims-deps"

# Print a step with status
# Usage: print_step <step_num> <total_steps> <message>
print_step() {
    local step_num=$1
    local total=$2
    local message=$3
    printf "[%d/%d] %b" "$step_num" "$total" "$message"
}

# Print done status
print_done() {
    printf " ${GREEN}done${NC}\n"
}

# Print skipped status with reason
print_skipped() {
    local reason=$1
    printf " ${YELLOW}skipped${NC} (%s)\n" "$reason"
}

# Print error and exit
print_error() {
    local message=$1
    printf " ${RED}error${NC}\n"
    printf "${RED}Error:${NC} %s\n" "$message" >&2
    exit 1
}

# Print info message (indented)
print_info() {
    local message=$1
    printf "      %s" "$message"
}

# Get the main lims repository path
# Works whether we're in the main repo or a worktree
get_main_repo() {
    local git_common_dir
    git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null)

    if [[ -z "$git_common_dir" ]]; then
        echo ""
        return 1
    fi

    # If git-common-dir ends with .git, parent is main repo
    # If it ends with .git/worktrees/xxx, we need to go up further
    if [[ "$git_common_dir" == *"/worktrees/"* ]]; then
        # We're in a worktree, extract main .git path
        local main_git_dir="${git_common_dir%/worktrees/*}"
        dirname "$main_git_dir"
    else
        # We're in the main repo
        dirname "$git_common_dir"
    fi
}

# Check if we're in a lims repository
validate_lims_repo() {
    local main_repo
    main_repo=$(get_main_repo)

    if [[ -z "$main_repo" ]]; then
        printf "${RED}Error:${NC} Not in a git repository\n" >&2
        exit 1
    fi

    # Check if it looks like the lims repo (has Gemfile)
    if [[ ! -f "$main_repo/Gemfile" ]]; then
        printf "${RED}Error:${NC} Not in the lims repository\n" >&2
        exit 1
    fi

    echo "$main_repo"
}

# Check if a branch exists locally
branch_exists() {
    local branch=$1
    local main_repo=$2
    git -C "$main_repo" show-ref --verify --quiet "refs/heads/$branch"
}

# Check if a branch exists on remote (origin)
remote_branch_exists() {
    local branch=$1
    local main_repo=$2
    git -C "$main_repo" ls-remote --heads origin "$branch" 2>/dev/null | grep -q "$branch"
}

# Check if worktree path exists
worktree_exists() {
    local path=$1
    [[ -d "$path" ]]
}

# Get worktree path for a branch
get_worktree_path() {
    local branch=$1
    echo "$WORKTREE_BASE/$branch"
}

# ============================================================================
# Dependency Caching
# ============================================================================

# Get fingerprint for bundle dependencies (hash of Gemfile.lock)
get_bundle_fingerprint() {
    local repo_path=$1
    local lockfile="$repo_path/Gemfile.lock"
    if [[ -f "$lockfile" ]]; then
        shasum -a 256 "$lockfile" | cut -d' ' -f1
    else
        echo ""
    fi
}

# Get fingerprint for yarn dependencies (hash of yarn.lock)
get_yarn_fingerprint() {
    local repo_path=$1
    local lockfile="$repo_path/yarn.lock"
    if [[ -f "$lockfile" ]]; then
        shasum -a 256 "$lockfile" | cut -d' ' -f1
    else
        echo ""
    fi
}

# Get cache path for bundle
get_bundle_cache_path() {
    local fingerprint=$1
    echo "$CACHE_DIR/bundle/$fingerprint"
}

# Get cache path for yarn
get_yarn_cache_path() {
    local fingerprint=$1
    echo "$CACHE_DIR/yarn/$fingerprint"
}

# Check if bundle cache exists for fingerprint
bundle_cache_exists() {
    local fingerprint=$1
    [[ -n "$fingerprint" ]] && [[ -d "$(get_bundle_cache_path "$fingerprint")" ]]
}

# Check if yarn cache exists for fingerprint
yarn_cache_exists() {
    local fingerprint=$1
    [[ -n "$fingerprint" ]] && [[ -d "$(get_yarn_cache_path "$fingerprint")" ]]
}

# Restore bundle from cache
restore_bundle_cache() {
    local fingerprint=$1
    local target_path=$2
    local cache_path
    cache_path=$(get_bundle_cache_path "$fingerprint")

    mkdir -p "$target_path/vendor"
    cp -R "$cache_path" "$target_path/vendor/bundle"
}

# Restore yarn from cache
restore_yarn_cache() {
    local fingerprint=$1
    local target_path=$2
    local cache_path
    cache_path=$(get_yarn_cache_path "$fingerprint")

    cp -R "$cache_path" "$target_path/node_modules"
}

# Save bundle to cache
save_bundle_cache() {
    local fingerprint=$1
    local source_path=$2
    local cache_path
    cache_path=$(get_bundle_cache_path "$fingerprint")

    mkdir -p "$(dirname "$cache_path")"
    # Remove old cache if exists and copy new
    rm -rf "$cache_path"
    cp -R "$source_path/vendor/bundle" "$cache_path"
}

# Save yarn to cache
save_yarn_cache() {
    local fingerprint=$1
    local source_path=$2
    local cache_path
    cache_path=$(get_yarn_cache_path "$fingerprint")

    mkdir -p "$(dirname "$cache_path")"
    # Remove old cache if exists and copy new
    rm -rf "$cache_path"
    cp -R "$source_path/node_modules" "$cache_path"
}
