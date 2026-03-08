{ config, pkgs, lib, ... }:

{
  programs.tmux = {
    enable = true;
  };

  home.file.".tmux.conf".source = ../config/tmux/tmux.conf;

  home.file.".tmux-lims.sh" = {
    source = ../config/tmux/tmux-lims.sh;
    executable = true;
  };
}
