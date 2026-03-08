{ config, pkgs, lib, ... }:

{
  # Ghostty is installed as a macOS app, not via Nix.
  # We just manage the config file.
  xdg.configFile."ghostty/config/config" = {
    source = ../config/ghostty/config;
  };
}
