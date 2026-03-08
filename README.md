# dotfiles.nix

Declarative development environment managed with [Nix](https://nixos.org/) and [Home Manager](https://github.com/nix-community/home-manager).

One command bootstraps a new machine with all tools and configs.

## Quick Start

### Bootstrap a fresh machine

```bash
# 1. Install Nix (if not already installed)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# 2. Clone this repo
nix-shell -p git --run "git clone https://github.com/EthanOrlander/dotfiles.nix.git ~/dotfiles.nix"

# 3. Apply the configuration
cd ~/dotfiles.nix
nix run home-manager -- switch --flake '.#work-macbook'

# 4. Set up secrets (once per machine)
cat > ~/.secrets.sh << 'EOF'
# Machine-local secrets -- not tracked in git
export LIMS_PROD_DB_URL="postgresql://..."
alias rails-prod-readonly='DISABLE_SPRING=1 DATABASE_URL="$LIMS_PROD_DB_URL" bundle exec rails'
EOF

# 5. Auth CLI tools (once per machine)
gh auth login
glab auth login
```

### Day-to-day usage

```bash
cd ~/dotfiles.nix

# Apply changes after editing configs
just switch

# Update all Nix packages
just update && just switch

# Check flake validity
just check
```

## Structure

```
flake.nix              # Entry point: nixpkgs + home-manager inputs
home/
  default.nix          # Shared config (imports all modules, declares packages)
  shell.nix            # Zsh: aliases, PATH, NVM, direnv
  git.nix              # Git: LFS, global gitignore
  tmux.nix             # Tmux config + session launcher
  neovim.nix           # Neovim + Lua config (Lazy.nvim manages plugins)
  ghostty.nix          # Ghostty terminal config
  btop.nix             # btop system monitor config
  direnv.nix           # direnv + nix-direnv
  gh.nix               # GitHub CLI
  glab.nix             # GitLab CLI
  scripts.nix          # Custom scripts (~/.local/bin)
  hosts/
    work-macbook.nix   # Machine-specific: username, email, paths
config/
  nvim/                # Neovim Lua config (symlinked to ~/.config/nvim)
  ghostty/             # Ghostty config
  tmux/                # tmux.conf + session launcher
  btop/                # btop config
  scripts/             # worktree helper, rubocop wrappers
```

## Adding a new machine

1. Create `home/hosts/<machine-name>.nix` with `home.username` and `home.homeDirectory`
2. Add a new entry to `homeConfigurations` in `flake.nix`
3. Run `just bootstrap <machine-name>` on that machine

## Secrets

Secrets are **never** committed. Each machine has `~/.secrets.sh` (sourced by zsh) for environment variables and aliases containing credentials. CLI tools (gh, glab) manage their own auth tokens via their `auth login` commands.
