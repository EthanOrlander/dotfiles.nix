{ ... }:

{
  programs.mise = {
    enable = true;
    globalConfig = {
      tools = {
        node = "22.22.0";
        python = "latest";
      };
    };
  };
}
