{ config, pkgs, lib, ... }:

{
  home.file.".local/bin/worktree" = {
    source = ../config/scripts/worktree;
    executable = true;
  };

  home.file.".local/bin/worktree.d/common.sh" = {
    source = ../config/scripts/worktree.d/common.sh;
    executable = true;
  };

  home.file.".local/bin/worktree.d/create.sh" = {
    source = ../config/scripts/worktree.d/create.sh;
    executable = true;
  };

  home.file.".local/bin/worktree.d/delete.sh" = {
    source = ../config/scripts/worktree.d/delete.sh;
    executable = true;
  };

  home.file.".local/bin/rubocop-direnv" = {
    source = ../config/scripts/rubocop-direnv;
    executable = true;
  };

  home.file.".local/bin/rubocop-format" = {
    source = ../config/scripts/rubocop-format;
    executable = true;
  };
}
