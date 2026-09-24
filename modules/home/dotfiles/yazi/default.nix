{ config, lib, pkgs, username, ... }:

let
  cfg = config.modules.home.yazi;

  hmConfig = config.home-manager.users.${username};
  hmStylix = hmConfig.stylix;
  colors = hmConfig.lib.stylix.colors.withHashtag;
  accent = colors.${config.modules.home.stylix.accent};
in
{
  options = {
    modules = {
      home = {
        yazi = {
          enable = lib.mkEnableOption "yazi file manager";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            yazi = {
              enable = true;
              # Adds `y` (HM's shellWrapperName default since stateVersion
              # 26.05), which cds to yazi's last directory on exit.
              enableFishIntegration = true;

              plugins = {
                # Git status signs in the linemode; fed by the fetchers below.
                git = {
                  package = pkgs.yaziPlugins.git;
                  setup = true;
                };
                full-border = {
                  package = pkgs.yaziPlugins.full-border;
                  setup = true;
                };
                smart-enter = pkgs.yaziPlugins.smart-enter;
                chmod = pkgs.yaziPlugins.chmod;
              };

              settings = {
                mgr = {
                  sort_by = "natural";
                  linemode = "size";
                };

                preview = {
                  max_width = 1000;
                  max_height = 1000;
                };

                tasks = {
                  file_workers = 5;
                  preload_workers = 5;
                  bizarre_retry = 5;
                };

                # GUI apps are orphans: niri has no xdg-open backend, so
                # xdg-open waits for the app, which would otherwise sit in the
                # task list and trigger the quit prompt.
                opener = {
                  edit = [
                    {
                      run = "zeditor %s";
                      orphan = true;
                      desc = "Edit with Zed";
                    }
                    # Bulk rename/create edit a temp file with the first
                    # blocking opener and read it back once that exits.
                    {
                      run = "zeditor --wait %s";
                      block = true;
                      desc = "Edit with Zed (wait)";
                    }
                  ];
                  # %s1 runs xdg-open once per file; it takes one argument.
                  open = [
                    {
                      run = "xdg-open %s1";
                      orphan = true;
                      desc = "Open with default app";
                    }
                  ];
                  reveal = [
                    {
                      run = "xdg-open %d1";
                      orphan = true;
                      desc = "Reveal in default file manager";
                    }
                  ];
                };

                open = {
                  prepend_rules = [
                    {
                      mime = "text/*";
                      use = [
                        "edit"
                        "open"
                        "reveal"
                      ];
                    }
                    {
                      mime = "video/*";
                      use = [
                        "open"
                        "reveal"
                      ];
                    }
                    {
                      mime = "application/json";
                      use = [
                        "edit"
                        "open"
                        "reveal"
                      ];
                    }
                    {
                      url = "*.{md,nix,toml,yaml,yml}";
                      use = [
                        "edit"
                        "open"
                        "reveal"
                      ];
                    }
                  ];
                };

                plugin = {
                  prepend_fetchers = [
                    {
                      url = "*";
                      run = "git";
                      group = "git";
                    }
                    {
                      url = "*/";
                      run = "git";
                      group = "git";
                    }
                  ];
                };
              };

              keymap = {
                mgr = {
                  prepend_keymap = [
                    {
                      on = [ "g" "d" ];
                      run = "cd ~/downloads";
                      desc = "Go to downloads";
                    }
                    {
                      on = [ "g" "p" ];
                      run = "cd ~/projects";
                      desc = "Go to projects";
                    }
                    {
                      on = [ "g" "n" ];
                      run = "cd ~/documents";
                      desc = "Go to documents";
                    }
                    {
                      on = [ "g" "D" ];
                      run = "cd /data";
                      desc = "Go to data volume";
                    }
                    {
                      on = [ "<C-v>" ];
                      run = "paste --force";
                      desc = "Paste yank (overwrite)";
                    }
                    {
                      on = [ "<S-Down>" ];
                      run = "seek 5";
                      desc = "Scroll preview down";
                    }
                    {
                      on = [ "<S-Up>" ];
                      run = "seek -5";
                      desc = "Scroll preview up";
                    }
                    # No --block: yazi would hide until the new kitty closes.
                    {
                      on = [ "T" ];
                      run = "shell --orphan 'kitty --working-directory \"$PWD\"'";
                      desc = "Open kitty here";
                    }
                    {
                      on = [ "l" ];
                      run = "plugin smart-enter";
                      desc = "Enter the child directory, or open the file";
                    }
                    {
                      on = [ "c" "m" ];
                      run = "plugin chmod";
                      desc = "Chmod on selected files";
                    }
                  ];
                };
              };

              # The theme (colors, icons, filetype rules) comes from stylix's
              # yazi target; most keys of the old hand-written one (hovered,
              # mode_normal, permissions_*, …) no longer exist in yazi 26.
              # On top of it: the accent where Catppuccin's yazi theme puts
              # its accent (hovered file, selection, normal mode, borders),
              # and the active tab. Directories keep stylix's blue: a file type
              # color, not UI.
              theme = lib.mkIf (hmStylix.enable && hmStylix.targets.yazi.enable) {
                mgr = {
                  marker_selected = lib.mkForce {
                    fg = accent;
                    bg = accent;
                  };
                  count_selected = lib.mkForce {
                    fg = colors.base00;
                    bg = accent;
                  };
                };

                tabs = {
                  active = lib.mkForce {
                    fg = colors.base00;
                    bg = accent;
                    bold = true;
                  };
                  inactive = lib.mkForce {
                    fg = accent;
                    bg = colors.base01;
                  };
                };

                mode = {
                  normal_main = lib.mkForce {
                    fg = colors.base00;
                    bg = accent;
                    bold = true;
                  };
                  normal_alt = lib.mkForce {
                    fg = accent;
                    bg = colors.base00;
                  };
                };

                indicator = {
                  current = lib.mkForce {
                    fg = colors.base00;
                    bg = accent;
                    bold = true;
                  };
                };

                pick = {
                  border = lib.mkForce {
                    fg = accent;
                  };
                };

                input = {
                  border = lib.mkForce {
                    fg = accent;
                  };
                };

                tasks = {
                  border = lib.mkForce {
                    fg = accent;
                  };
                };

                # Not set by stylix: yazi's preset "blue" would be the
                # terminal's blue.
                which = {
                  border = {
                    fg = accent;
                  };
                };

                confirm = {
                  border = {
                    fg = accent;
                  };
                  title = {
                    fg = accent;
                  };
                };

                spot = {
                  border = {
                    fg = accent;
                  };
                  title = {
                    fg = accent;
                  };
                  tbl_cell = {
                    fg = accent;
                    reversed = true;
                  };
                };

                # Stylix still writes these as [completion] and help's
                # on/run/desc/footer, which yazi 26 renamed to [cmp] and
                # chord/action; forced so the dead help keys go too.
                cmp = {
                  border = {
                    fg = accent;
                  };
                  active = {
                    fg = accent;
                    bg = colors.base03;
                  };
                  inactive = {
                    fg = colors.base05;
                  };
                };

                help = lib.mkForce {
                  border = {
                    fg = accent;
                  };
                  chord = {
                    fg = colors.magenta;
                  };
                  action = {
                    fg = colors.base05;
                  };
                  hovered = {
                    fg = accent;
                    bg = colors.base03;
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
