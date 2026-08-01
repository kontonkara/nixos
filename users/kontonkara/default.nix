{ username, inputs, config, host, pkgs, ... }:

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
       hashedPasswordFile = config.sops.secrets."kontonkara".path;
      };
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs username host;
    };
    users = {
      ${username} = {
        home = {
          username = "${username}";
          homeDirectory = "/home/${username}";
          stateVersion = config.system.stateVersion;
        };
      };
    };
    backupFileExtension = "backup";
  };
}