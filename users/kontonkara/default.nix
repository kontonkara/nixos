{ username, pkgs, ... }:

{
  users = {
    users = {
      ${username} = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" ];
      packages = with pkgs; [
        tree
        telegram-desktop
        keepassxc
        vscode
      ];
      hashedPasswordFile = "/etc/nixos/secrets/user-password";
      };
    };
  };
}