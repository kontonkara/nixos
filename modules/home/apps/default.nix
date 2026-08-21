{
  config,
  lib,
  username,
  inputs,
  pkgs,
  ...
}:

let
  cfg = config.modules.home.apps;
in
{
  options = {
    modules = {
      home = {
        apps = {
          enable = lib.mkEnableOption "home applications";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
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
  };
}
