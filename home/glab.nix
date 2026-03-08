{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    glab
  ];

  # Only manage the non-secret parts of glab config.
  # Tokens are managed by `glab auth login` per machine.
  xdg.configFile."glab-cli/config.yml".text = ''
    git_protocol: ssh
    editor:
    browser:
    glamour_style: dark
    check_update: true
    display_hyperlinks: false
    host: gitlab.com
    no_prompt: false
    telemetry: true
  '';
}
