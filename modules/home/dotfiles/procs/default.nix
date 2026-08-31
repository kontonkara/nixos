{
  config,
  lib,
  pkgs,
  username,
  ...
}:

let
  cfg = config.modules.home.procs;
in
{
  options.modules.home.procs.enable = lib.mkEnableOption "procs";

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} = {
      home.packages = [
        pkgs.procs
      ];

      xdg.configFile."procs/config.toml".text = ''
        [[columns]]
        kind = "Pid"
        style = "BrightYellow|Yellow"
        numeric_search = true
        nonnumeric_search = false
        align = "Right"

        [[columns]]
        kind = "User"
        style = "BrightGreen|Green"
        numeric_search = false
        nonnumeric_search = true
        align = "Left"

        [[columns]]
        kind = "UsageCpu"
        style = "ByPercentage"
        numeric_search = false
        nonnumeric_search = false
        align = "Right"

        [[columns]]
        kind = "UsageMem"
        style = "ByPercentage"
        numeric_search = false
        nonnumeric_search = false
        align = "Right"

        [[columns]]
        kind = "CpuTime"
        style = "BrightCyan|Cyan"
        numeric_search = false
        nonnumeric_search = false
        align = "Right"

        [[columns]]
        kind = "Command"
        style = "BrightWhite|Black"
        numeric_search = false
        nonnumeric_search = true
        align = "Left"

        [style]
        header = "BrightWhite|Black"
        unit = "BrightWhite|Black"
        tree = "BrightWhite|Black"

        [search]
        numeric_search = "Exact"
        nonnumeric_search = "Partial"
        logic = "And"
        case = "Smart"

        [display]
        show_self = false
        show_self_parents = false
        show_thread = false
        show_thread_in_tree = true
        show_parent_in_tree = true
        show_children_in_tree = true
        show_header = true
        show_footer = false
        cut_to_terminal = true
        cut_to_pager = false
        cut_to_pipe = false
        color_mode = "Auto"
        separator = "|"
        ascending = "^"
        descending = "v"
        tree_symbols = ["|", "-", "+", "+", "`"]
        abbr_sid = true
        theme = "Auto"
        show_kthreads = true

        [sort]
        column = 2
        order = "Descending"

        [pager]
        mode = "Auto"
        detect_width = false
        use_builtin = false
      '';
    };
  };
}
