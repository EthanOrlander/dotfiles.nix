{ config, pkgs, lib, ... }:

{
  imports = [
    ../glab.nix
  ];

  home.username = "Ethan.Orlander";
  home.homeDirectory = "/Users/Ethan.Orlander";

  home.packages = with pkgs; [
    awscli2
    k9s
    kubelogin
  ];

  programs.zsh.shellAliases = {
    lims = "~/.tmux-lims.sh";
  };

  programs.git = {
    settings = {
      user.name = "Ethan Orlander";
      user.email = "ethan.orlander@neuralink.com";
    };
    includes = [
      { path = "/Users/Ethan.Orlander/code/sw/ops/nlk_speed_up_git/.gitconfig"; }
    ];
  };
}
