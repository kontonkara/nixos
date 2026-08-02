{ username, inputs, config, host, pkgs, ... }:

{
  users = {
    mutableUsers = false;
    users = {
      ${username} = {
      isNormalUser = true;
      extraGroups = [
        "networkmanager" 
        "wheel"
        "input"
        "render"
        "uinput"
        "video"
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