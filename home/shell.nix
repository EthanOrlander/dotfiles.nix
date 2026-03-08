{ config, pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    sessionVariables = {
      DIRENV_LOG_FORMAT = "\\033[22m\\033[2mdirenv: %s\\033[0m\\033[22m";
    };

    initContent = ''
      # Tailscale (macOS)
      if [[ -f "/Applications/Tailscale.app/Contents/MacOS/Tailscale" ]]; then
        alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
      fi

      # VSCode direnv fix
      [[ -n "$VSCODE_INJECTION" && -z "$VSCODE_TERMINAL_DIRENV_LOADED" && -f .envrc ]] && cd .. && cd - && export VSCODE_TERMINAL_DIRENV_LOADED=1

      # Source machine-local secrets (not tracked in git)
      [[ -f ~/.secrets.sh ]] && source ~/.secrets.sh
    '';
  };

  home.sessionPath = [
    "$HOME/.local/bin"
  ];
}
