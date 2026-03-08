{ config, pkgs, lib, ... }:

{
  xdg.configFile."btop/btop.conf" = {
    source = ../config/btop/btop.conf;
  };
}
