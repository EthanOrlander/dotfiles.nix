#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

usage() {
    cat <<EOF
Usage: worktree delete <branch-name> [options]
       worktree d <branch-name> [options]

Remove a git worktree and optionally delete the branch.

Options:
    -k, --keep-branch   Don't delete the git branch
    -f, --force         Force removal even with uncommitted changes
    -h, --help          Show this help message

Examples:
    worktree delete my-feature
    wt d my-feature --keep-branch
    wt d abandoned-feature --force
EOF
}

do_delete() {
    local branch=""
    local keep_branch=false
    local force=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -k|--keep-branch)
                keep_branch=true
                shift
                ;;
            -f|--force)
                force=true
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

    local total_steps=2
    if [[ "$keep_branch" == false ]]; then
        total_steps=3
    fi
    local current_step=0

    # Step 1: Remove worktree
    current_step=$((current_step + 1))
    print_step $current_step $total_steps "Removing worktree at $worktree_path..."
    if ! worktree_exists "$worktree_path"; then
        print_skipped "does not exist"
    else
        local remove_args=""
        if [[ "$force" == true ]]; then
            remove_args="--force"
        fi

        if ! git -C "$main_repo" worktree remove $remove_args "$worktree_path" 2>/dev/null; then
            if [[ "$force" == false ]]; then
                print_error "Failed to remove worktree. Use --force to remove with uncommitted changes"
            else
                print_error "Failed to remove worktree"
            fi
        fi
        print_done
    fi

    # Step 2: Prune worktrees (cleanup stale entries)
    current_step=$((current_step + 1))
    print_step $current_step $total_steps "Pruning stale worktree entries..."
    git -C "$main_repo" worktree prune 2>/dev/null
    print_done

    # Step 3: Delete branch (unless --keep-branch)
    if [[ "$keep_branch" == false ]]; then
        current_step=$((current_step + 1))
        print_step $current_step $total_steps "Deleting branch '$branch'..."
        if ! branch_exists "$branch" "$main_repo"; then
            print_skipped "does not exist"
        else
            local delete_flag="-d"
            if [[ "$force" == true ]]; then
                delete_flag="-D"
            fi

            if ! git -C "$main_repo" branch $delete_flag "$branch" 2>/dev/null; then
                if [[ "$force" == false ]]; then
                    print_error "Branch not fully merged. Use --force to delete anyway"
                else
                    print_error "Failed to delete branch"
                fi
            fi
            print_done
        fi
    fi

    printf "\n${GREEN}Worktree removed successfully${NC}\n"
}
