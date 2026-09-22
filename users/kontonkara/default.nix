{ pkgs, inputs, config, ... }:

{
  users = {
    mutableUsers = false;
    users = {
      kontonkara = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        packages = with pkgs; [
          tree
          telegram-desktop
          keepassxc
          inputs.llm-agents.packages.x86_64-linux.mimo-code
        ];
        hashedPasswordFile = config.sops.secrets."kontonkara".path;
      };
    };
  };
}