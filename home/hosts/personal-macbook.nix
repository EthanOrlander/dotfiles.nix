{ config, pkgs, lib, ... }:

{
  home.username = "ethanorlander";
  home.homeDirectory = "/Users/ethanorlander";

  programs.git = {
    settings = {
      user.name = "Ethan Orlander";
      user.email = "ethanorlander@gmail.com";
    };
  };
}
