{ username, inputs, pkgs, ... }:

{
  home-manager = {
    users = {
      ${username} = {
        home = {
          packages = with pkgs; [
            telegram-desktop
            keepassxc
            vscode
            vulkan-tools
            spotify
          ];
        };
      };
    };
  };
}