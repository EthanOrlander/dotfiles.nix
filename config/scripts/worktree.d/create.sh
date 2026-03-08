#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
    cat <<EOF
Usage: worktree create <branch-name> [options]
       worktree c <branch-name> [options]

Create a new git worktree with automatic dependency installation.

Options:
    --base <ref>    Create branch from specific ref (default: current HEAD)
    -t, --tmux      Open worktree in a new tmux window
    -h, --help      Show this help message

Examples:
    worktree create my-feature
    wt c my-feature --tmux
    wt c fix-bug --base main
EOF
}

do_create() {
    local branch=""
    local base_ref="HEAD"
    local open_tmux=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --base)
                base_ref="$2"
                shift 2
                ;;
            -t|--tmux)
                open_tmux=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -*)
                printf "${RED}Error:${NC} Unknown option: %s\n" "$1" >&2
                usage
                exit 1
                ;;
            *)
                if [[ -z "$branch" ]]; then
                    branch="$1"
                else
                    printf "${RED}Error:${NC} Unexpected argument: %s\n" "$1" >&2
                    usage
                    exit 1
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$branch" ]]; then
        printf "${RED}Error:${NC} Branch name is required\n" >&2
        usage
        exit 1
    fi

    # Validate we're in lims repo
    local main_repo
    main_repo=$(validate_lims_repo)

    local worktree_path
    worktree_path=$(get_worktree_path "$branch")
    local total_steps=5

    # Step 1: Create/fetch branch
    print_step 1 $total_steps "Setting up branch '$branch'..."
    if branch_exists "$branch" "$main_repo"; then
        print_skipped "exists locally"
    elif remote_branch_exists "$branch" "$main_repo"; then
        # Fetch and create tracking branch
        if ! git -C "$main_repo" fetch origin "$branch" 2>/dev/null; then
            print_error "Failed to fetch branch from origin"
        fi
        if ! git -C "$main_repo" branch "$branch" "origin/$branch" 2>/dev/null; then
            print_error "Failed to create tracking branch"
        fi
        printf " ${GREEN}fetched from origin${NC}\n"
    else
        # Create new branch
        if ! git -C "$main_repo" branch "$branch" "$base_ref" 2>/dev/null; then
            print_error "Failed to create branch from $base_ref"
        fi
        printf " ${GREEN}created${NC}\n"
    fi

    # Step 2: Create worktree
    print_step 2 $total_steps "Creating worktree at $worktree_path..."
    if worktree_exists "$worktree_path"; then
        print_skipped "already exists"
    else
        # Ensure parent directory exists
        mkdir -p "$WORKTREE_BASE"
        local wt_error
        wt_error=$(git -C "$main_repo" worktree add "$worktree_path" "$branch" 2>&1)
        if [[ $? -ne 0 ]]; then
            printf " ${RED}error${NC}\n"
            printf "${RED}Error:${NC} %s\n" "$wt_error" >&2
            exit 1
        fi
        print_done
    fi

    # Step 3: Symlink SSL certificates and copy env file
    print_step 3 $total_steps "Linking SSL certs & copying .env.development.local..."
    # Use absolute paths for symlinks
    local abs_main_repo
    abs_main_repo=$(cd "$main_repo" && pwd)
    ln -sf "$abs_main_repo/localhost.pem" "$worktree_path/localhost.pem"
    ln -sf "$abs_main_repo/localhost-key.pem" "$worktree_path/localhost-key.pem"
    if [[ -f "$abs_main_repo/.env.development.local" ]]; then
        cp "$abs_main_repo/.env.development.local" "$worktree_path/.env.development.local"
    fi
    print_done

    # Step 4: Install dependencies (with caching)
    print_step 4 $total_steps "Installing dependencies...\n"

    # Get fingerprints
    local bundle_fp yarn_fp
    bundle_fp=$(get_bundle_fingerprint "$worktree_path")
    yarn_fp=$(get_yarn_fingerprint "$worktree_path")

    local bundle_pid yarn_pid
    local bundle_log yarn_log
    local bundle_cached=false yarn_cached=false
    bundle_log=$(mktemp)
    yarn_log=$(mktemp)

    # Handle bundle
    if bundle_cache_exists "$bundle_fp"; then
        print_info "bundle (restoring from cache)..."
        (restore_bundle_cache "$bundle_fp" "$worktree_path" > "$bundle_log" 2>&1) &
        bundle_pid=$!
        bundle_cached=true
    else
        print_info "bundle install..."
        (cd "$worktree_path" && bundle install > "$bundle_log" 2>&1) &
        bundle_pid=$!
    fi

    # Handle yarn
    if yarn_cache_exists "$yarn_fp"; then
        print_info "yarn (restoring from cache)..."
        (restore_yarn_cache "$yarn_fp" "$worktree_path" > "$yarn_log" 2>&1) &
        yarn_pid=$!
        yarn_cached=true
    else
        print_info "yarn install..."
        (cd "$worktree_path" && yarn install > "$yarn_log" 2>&1) &
        yarn_pid=$!
    fi

    # Wait for bundle
    printf "\r      bundle "
    if [[ "$bundle_cached" == true ]]; then
        printf "(restoring from cache)..."
    else
        printf "install..."
    fi
    if wait $bundle_pid; then
        print_done
        # Save to cache if we did a fresh install
        if [[ "$bundle_cached" == false ]] && [[ -n "$bundle_fp" ]]; then
            save_bundle_cache "$bundle_fp" "$worktree_path" 2>/dev/null &
        fi
    else
        printf " ${RED}failed${NC}\n"
        printf "${YELLOW}Bundle output:${NC}\n"
        cat "$bundle_log"
    fi

    # Wait for yarn
    printf "      yarn "
    if [[ "$yarn_cached" == true ]]; then
        printf "(restoring from cache)..."
    else
        printf "install..."
    fi
    if wait $yarn_pid; then
        print_done
        # Save to cache if we did a fresh install
        if [[ "$yarn_cached" == false ]] && [[ -n "$yarn_fp" ]]; then
            save_yarn_cache "$yarn_fp" "$worktree_path" 2>/dev/null &
        fi
    else
        printf " ${RED}failed${NC}\n"
        printf "${YELLOW}Yarn output:${NC}\n"
        cat "$yarn_log"
    fi

    # Wait for any background cache saves
    wait

    # Cleanup temp files
    rm -f "$bundle_log" "$yarn_log"

    # Step 5: Complete
    print_step 5 $total_steps "Complete!\n"
    printf "\n${GREEN}Worktree ready at:${NC} %s\n" "$worktree_path"

    # Open in tmux if requested
    if [[ "$open_tmux" == true ]]; then
        if command -v tmux &> /dev/null && [[ -n "$TMUX" ]]; then
            tmux new-window -n "$branch" -c "$worktree_path"
            printf "${BLUE}Opened in new tmux window: %s${NC}\n" "$branch"
        else
            printf "${YELLOW}Warning:${NC} tmux not available or not in a tmux session\n"
        fi
    fi
}
