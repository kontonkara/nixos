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

              theme = {
                mgr = {
                  hovered = {
                    fg = "#7fc8ff";
                    bg = "#1e2a36";
                  };
                  preview_hovered = {
                    underline = true;
                    fg = "#7fc8ff";
                    bg = "#1e2a36";
                  };
                  find_keyword = {
                    fg = "#e0af68";
                    italic = true;
                  };
                  find_position = {
                    fg = "#bb9af7";
                    bg = "reset";
                    italic = true;
                  };
                  marker = {
                    fg = "#9ece6a";
                    bg = "#1e2a36";
                  };
                  cwd = {
                    fg = "#7fc8ff";
                    bold = true;
                  };
                  hover_cursor = {
                    fg = "#0f1419";
                    bg = "#7fc8ff";
                  };
                  count = {
                    fg = "#0f1419";
                    bg = "#7aa2f7";
                  };
                };

                status = {
                  separator_open = "";
                  separator_close = "";
                  separator_style = {
                    fg = "#3b4261";
                    bg = "reset";
                  };
                  mode_normal = {
                    fg = "#0f1419";
                    bg = "#7fc8ff";
                    bold = true;
                  };
                  mode_select = {
                    fg = "#0f1419";
                    bg = "#9ece6a";
                    bold = true;
                  };
                  mode_unset = {
                    fg = "#0f1419";
                    bg = "#e0af68";
                    bold = true;
                  };
                  progress_label = {
                    fg = "#c0caf5";
                    bold = true;
                  };
                  progress_normal = {
                    fg = "#7fc8ff";
                    bg = "#1a1b26";
                  };
                  progress_error = {
                    fg = "#f7768e";
                    bg = "#1a1b26";
                  };
                  permissions_t = {
                    fg = "#7fc8ff";
                  };
                  permissions_r = {
                    fg = "#9ece6a";
                  };
                  permissions_w = {
                    fg = "#f7768e";
                  };
                  permissions_x = {
                    fg = "#e0af68";
                  };
                  permissions_s = {
                    fg = "#565f89";
                  };
                };

                input = {
                  border = {
                    fg = "#3b4261";
                  };
                  title = {
                    fg = "#7fc8ff";
                  };
                  value = {
                    fg = "#c0caf5";
                  };
                  selected = {
                    reversed = true;
                  };
                };

                completion = {
                  border = {
                    fg = "#3b4261";
                  };
                  active = {
                    fg = "#7fc8ff";
                    bg = "#1e2a36";
                  };
                  inactive = { };
                };

                tasks = {
                  border = {
                    fg = "#3b4261";
                  };
                  title = {
                    fg = "#7fc8ff";
                  };
                  hovered = {
                    underline = true;
                  };
                };

                which = {
                  mask = {
                    bg = "#1a1b26";
                  };
                  cand = {
                    fg = "#9ece6a";
                  };
                  rest = {
                    fg = "#565f89";
                  };
                  desc = {
                    fg = "#c0caf5";
                  };
                  separator = "  ";
                  separator_style = {
                    fg = "#3b4261";
                  };
                };

                help = {
                  on = {
                    fg = "#7fc8ff";
                  };
                  exec = {
                    fg = "#9ece6a";
                  };
                  desc = {
                    fg = "#c0caf5";
                  };
                  hovered = {
                    bg = "#1e2a36";
                    bold = true;
                  };
                  footer = {
                    fg = "#565f89";
                    italic = true;
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
