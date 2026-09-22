{ username, inputs, pkgs, ... }:

{
  home-manager = {
    users = {
      ${username} = {
        home = {
          packages = with pkgs; [
            tree
            telegram-desktop
            keepassxc
            inputs.llm-agents.packages.x86_64-linux.mimo-code
          ];
        };
      };
    };
  };
}