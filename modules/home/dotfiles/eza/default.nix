{
  config,
  lib,
  username,
  ...
}:

let
  cfg = config.modules.home.eza;
in
{
  options.modules.home.eza.enable = lib.mkEnableOption "eza";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username}.programs.eza = {
      enable = true;
      colors = "auto";
      enableFishIntegration = true;
      git = true;
      icons = "auto";

      extraOptions = [
        "--classify=auto"
        "--color-scale=age"
        "--color-scale-mode=gradient"
        "--group-directories-first"
        "--header"
        "--hyperlink"
        "--time-style=long-iso"
      ];
    };
  };
}
