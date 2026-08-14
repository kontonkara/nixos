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
            (prismlauncher.override {
              jdks = [
                zulu8
                zulu17
                zulu21
                zulu25
              ];
            })
            zoom-us
            inputs.llm-agents.packages.x86_64-linux.codex
          ];
        };
      };
    };
  };
}
