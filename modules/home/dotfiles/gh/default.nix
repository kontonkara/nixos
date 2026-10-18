{ config, lib, pkgs, inputs, username, ... }:

let
  cfg = config.modules.home.gh;
in
{
  options = {
    modules = {
      home = {
        gh = {
          enable = lib.mkEnableOption "the GitHub CLI";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          home = {
            # Not programs.gh: its config.yml is a read-only link into the
            # store, and `gh auth login` writes that file as it logs in.
            packages = [
              pkgs.gh
            ];

            # gh keeps config.yml itself, and the token beside it in hosts.yml
            # or the keyring; the protocol is set again at every activation,
            # once the old generation's links are gone. The remotes are SSH
            # ones, with the key git signs with.
            activation = {
              ghGitProtocol = inputs.home-manager.lib.hm.dag.entryAfter [ "linkGeneration" ] ''
                run ${lib.getExe pkgs.gh} config set git_protocol ssh
              '';
            };
          };
        };
      };
    };
  };
}
