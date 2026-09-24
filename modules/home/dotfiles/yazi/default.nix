{ config, lib, username, ... }:

let
  cfg = config.modules.home.yazi;
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
              enableFishIntegration = true;
              shellWrapperName = "y";

              settings = {
                mgr = {
                  ratio = [
                    1
                    4
                    3
                  ];
                  sort_by = "natural";
                  sort_dir_first = true;
                  sort_sensitive = false;
                  sort_reverse = false;
                  linemode = "size";
                  show_hidden = false;
                  show_symlink = true;
                };

                preview = {
                  max_width = 1000;
                  max_height = 1000;
                  image_delay = 30;
                  image_filter = "triangle";
                  image_quality = 75;
                };

                tasks = {
                  file_workers = 5;
                  plugin_workers = 5;
                  fetch_workers = 5;
                  preload_workers = 5;
                  process_workers = 5;
                  bizarre_retry = 5;
                };

                opener = {
                  edit = [
                    {
                      run = "code %s";
                      block = true;
                      desc = "Edit with VS Code";
                      for = "unix";
                    }
                  ];
                  open = [
                    {
                      run = "xdg-open %s";
                      desc = "Open with default app";
                      for = "linux";
                    }
                  ];
                  reveal = [
                    {
                      run = "xdg-open %d1";
                      desc = "Reveal in default file manager";
                      for = "linux";
                    }
                  ];
                };

                open = {
                  prepend_rules = [
                    {
                      url = "*/";
                      use = [
                        "edit"
                        "open"
                        "reveal"
                      ];
                    }
                    {
                      mime = "text/*";
                      use = [
                        "edit"
                        "open"
                        "reveal"
                      ];
                    }
                    {
                      mime = "image/*";
                      use = [
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
                    {
                      on = [ "T" ];
                      run = "shell --block --orphan 'kitty --working-directory \"$PWD\"'";
                      desc = "Open kitty here";
                    }
                  ];
                };
              };

              # The theme (colors, icons, filetype rules) comes from stylix's
              # yazi target; most keys of the old hand-written one (hovered,
              # mode_normal, permissions_*, …) no longer exist in yazi 26.
            };
          };
        };
      };
    };
  };
}
