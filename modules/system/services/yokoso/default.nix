{ config, lib, pkgs, inputs, username, ... }:

let
  cfg = config.modules.system.services.yokoso;

  niriOutputs = config.modules.home.niri.outputs;

  hm = config.home-manager.users.${username};
  hmStylix = hm.stylix;
  colors = hm.lib.stylix.colors;
  # base05 at an alpha: base16 has no muted foreground that every scheme
  # keeps readable on base00.
  faded = alpha: "#${alpha}${colors.base05}";

  # Noctalia's avatar, if it has one, and where yokoso looks for it.
  avatar = hm.programs.noctalia.settings.shell.avatar_path or "";
  icon = "/var/lib/AccountsService/icons/${username}";
in
{
  imports = [
    inputs.yokoso.nixosModules.default
  ];

  options = {
    modules = {
      system = {
        services = {
          yokoso = {
            enable = lib.mkEnableOption "the yokoso greeter on greetd";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      yokoso = {
        enable = true;
        settings = lib.mkMerge [
          # The desktop's scale (niri's output), not the one the panel's DPI
          # gives: the login screen comes up the same size as the desktop.
          (lib.mkIf (config.modules.home.niri.enable && niriOutputs != { }) {
            scale = (lib.head (lib.attrValues niriOutputs)).scale or 1.0;
          })

          (lib.mkIf hmStylix.enable {
            theme = "stylix";
          })
        ];

        # The desktop's cursor (yokoso sizes it with the login screen).
        cursor = lib.mkIf (hmStylix.enable && hmStylix.cursor != null) {
          inherit (hmStylix.cursor) package name size;
        };

        # The desktop's palette, accent and font. No wallpaper: Noctalia's
        # live in the home directory the greeter can't read.
        themes = lib.mkIf hmStylix.enable {
          stylix = {
            extends = if hmStylix.polarity == "light" then "light" else "dark";
            colors = {
              background = "#${colors.base00}";
              text = "#${colors.base05}";
              subtext = faded "b3";
              dim = faded "80";
              field = "#${colors.base02}";
              accent = "#${colors.${config.modules.home.stylix.accent}}";
              error = "#${colors.base08}";
            };
            font = hmStylix.fonts.sansSerif.name;
          };
        };
      };
    };

    # Noctalia's avatar on the login screen too. It lives in the home
    # directory, which the greeter can't read (and this repository is public),
    # so a PNG copy goes where yokoso looks: AccountsService's icons, before
    # the greeter starts and whenever the picture changes.
    systemd = lib.mkIf (avatar != "") {
      services.yokoso-avatar = {
        description = "Copy ${username}'s avatar for the login screen";
        wantedBy = [ "multi-user.target" ];
        before = [ "greetd.service" ];
        unitConfig.RequiresMountsFor = [ avatar ];
        serviceConfig.Type = "oneshot";
        script = ''
          if [ ! -f ${lib.escapeShellArg avatar} ]; then
            rm -f ${icon}
          elif [ ! ${icon} -nt ${lib.escapeShellArg avatar} ]; then
            mkdir -p ${dirOf icon}
            ${lib.getExe' pkgs.imagemagick "magick"} ${lib.escapeShellArg avatar} -auto-orient \
              -resize '512x512^' -gravity center -extent 512x512 png:${icon}.new
            chmod 644 ${icon}.new
            mv ${icon}.new ${icon}
          fi
        '';
      };

      paths.yokoso-avatar = {
        wantedBy = [ "multi-user.target" ];
        pathConfig.PathChanged = avatar;
      };
    };
  };
}
