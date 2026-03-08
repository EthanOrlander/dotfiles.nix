{ config, pkgs, lib, ... }:

{
  imports = [
    ./shell.nix
    ./git.nix
    ./tmux.nix
    ./neovim.nix
    ./ghostty.nix
    ./btop.nix
    ./direnv.nix
    ./gh.nix
    ./mise.nix
    ./scripts.nix
  ];

  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    ripgrep
    tree-sitter
    btop
    claude-code
    go
    python313
    git-lfs
    curl
    wget
    tree
    jq
    fd
    just
  ];

  programs.home-manager.enable = true;
}
