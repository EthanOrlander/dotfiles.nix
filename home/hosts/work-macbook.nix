{ config, pkgs, lib, ... }:

{
  home.username = "Ethan.Orlander";
  home.homeDirectory = "/Users/Ethan.Orlander";

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
