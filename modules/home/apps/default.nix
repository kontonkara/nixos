{ username, inputs, pkgs, ... }:

{
  home-manager = {
    users = {
      ${username} = {
        home = {
          packages = with pkgs; [
            telegram-desktop
            keepassxc
            vulkan-tools
            spotify
            protonplus
            (bottles.override {
              removeWarningPopup = true;
            })
          ];
        };
      };
    };
  };
}
