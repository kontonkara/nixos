{ username, inputs, config, host, pkgs, ... }:

{
  programs = {
    fish = {
      enable = true;
      generateCompletions = true;
    };
  };

  users = {
    mutableUsers = false;
    users = {
      ${username} = {
      shell = pkgs.fish;
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
