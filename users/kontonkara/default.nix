{ config, lib, username, inputs, host, pkgs, ... }:

let
  cfg = config.modules.users.kontonkara;
in
{
  options = {
    modules = {
      users = {
        kontonkara = {
          enable = lib.mkEnableOption "user kontonkara";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
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
          ]
          # Both are root-equivalent: the docker socket and the system libvirt
          # instance. /dev/kvm is already 0666, so no kvm group.
          ++ lib.optional config.virtualisation.docker.enable "docker"
          ++ lib.optional config.virtualisation.libvirtd.enable "libvirtd";
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
  };
}
