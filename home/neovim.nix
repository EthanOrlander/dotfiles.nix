{ config, pkgs, lib, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
  };

  # Symlink the entire Neovim Lua config directory.
  # Lazy.nvim manages plugin installation at runtime.
  xdg.configFile."nvim" = {
    source = ../config/nvim;
    recursive = true;
  };
}
