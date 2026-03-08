{ config, pkgs, lib, ... }:

{
  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      pull.rebase = false;
    };
  };

  xdg.configFile."git/ignore".text = ''
    .direnv/
    .envrc.local
    **/.claude/settings.local.json
  '';
}
