{
  config,
  lib,
  username,
  pkgs,
  ...
}:

let
  cfg = config.modules.home.zed;
  zedPatched = pkgs.zed-editor.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ./patches/cursor-animation.patch
      ./patches/smooth-scroll.patch
    ];
  });
  zed = pkgs.symlinkJoin {
    name = "zed-editor-igpu-${lib.getVersion zedPatched}";
    paths = [ zedPatched ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm $out/bin/zeditor
      makeWrapper ${lib.getExe zedPatched} $out/bin/zeditor \
        --set DRI_PRIME 0 \
        --set __NV_PRIME_RENDER_OFFLOAD 0
    '';
  };
in
{
  options.modules.home.zed.enable = lib.mkEnableOption "Zed editor home configuration";

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs.zed-editor = {
            enable = true;
            package = zed;
            mutableUserSettings = false;
            mutableUserKeymaps = false;

            extensions = [
              "ansible"
              "catppuccin-icons"
              "crates-lsp"
              "dockerfile"
              "git-firefly"
              "gitlab-ci-ls"
              "github-actions"
              "go-snippets"
              "golangci-lint"
              "gosum"
              "helm"
              "nix"
              "opentofu"
              "terraform"
              "toml"
            ];

            extraPackages = with pkgs; [
              ansible-language-server
              ansible-lint
              crates-lsp
              delve
              gitlab-ci-ls
              golangci-lint
              golangci-lint-langserver
              gopls
              helm
              helm-ls
              nixd
              nixfmt
              opentofu
              package-version-server
              taplo
              terraform-ls
              yaml-language-server
              vscode-json-languageserver
            ];

            userSettings = {
              autosave = "on_focus_change";
              base_keymap = "VSCode";
              buffer_font_features = {
                calt = true;
                liga = true;
              };
              colorize_brackets = true;
              cursor_animation.enabled = true;
              cursor_blink = true;
              diagnostics.inline = {
                enabled = true;
                update_delay_ms = 150;
              };
              ensure_final_newline_on_save = true;
              format_on_save = "on";
              icon_theme = "Catppuccin Mocha";
              indent_guides = {
                enabled = true;
                coloring = "indent_aware";
              };
              load_direnv = "direct";
              file_scan_exclusions = [
                "**/.direnv"
                "**/result"
                "**/result-*"
              ];
              minimap.show = "never";
              remove_trailing_whitespace_on_save = true;
              restore_on_startup = "none";
              wrap_guides = [
                100
                120
              ];
              show_wrap_guides = true;
              smooth_scroll.enabled = true;
              soft_wrap = "editor_width";
              sticky_scroll.enabled = true;
              tab_size = 2;
              title_bar.show_sign_in = false;
              project_panel.dock = "left";
              outline_panel.dock = "left";
              agent.dock = "left";
              telemetry = {
                diagnostics = false;
                metrics = false;
              };
              window_decorations = "server";
              terminal = {
                shell = {
                  program = "${pkgs.fish}/bin/fish";
                };
                blinking = "on";
                font_family = "JetBrainsMono Nerd Font Mono";
              };
              languages = {
                Nix = {
                  language_servers = [
                    "nixd"
                    "!nil"
                  ];
                  format_on_save = "off";
                  formatter = {
                    external = {
                      command = "nixfmt";
                      arguments = [
                        "--quiet"
                        "--"
                      ];
                    };
                  };
                };
                Terraform.language_servers = [ "terraform-ls" ];
                helm_ls.settings = {
                  helm-ls = {
                    logLevel = "info";
                    yamlls.enabled = true;
                  };
                };
                yamlls.initialization_options = {
                  yaml.schemas = {
                    kubernetes = "templates/*.yaml";
                    "https://json.schemastore.org/github-workflow" = ".github/workflows/*";
                    "https://json.schemastore.org/github-action" = ".github/action.{yml,yaml}";
                    "https://json.schemastore.org/ansible-stable-2.9" =
                      "roles/*/{tasks,handlers,defaults,vars}/*.{yml,yaml}";
                    "https://json.schemastore.org/prettierrc" = ".prettierrc.{yml,yaml}";
                    "https://json.schemastore.org/kustomization" = "kustomization.{yml,yaml}";
                    "https://json.schemastore.org/ansible-playbook" = "*play*.{yml,yaml}";
                    "https://json.schemastore.org/chart" = "Chart.{yml,yaml}";
                    "https://json.schemastore.org/dependabot-v2" = ".github/dependabot.{yml,yaml}";
                    "https://json.schemastore.org/gitlab-ci" = "*gitlab-ci*.{yml,yaml}";
                    "https://raw.githubusercontent.com/OAI/OpenAPI-Specification/main/schemas/v3.1/schema.json" =
                      "*api*.{yml,yaml}";
                    "https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json" =
                      "*docker-compose*.{yml,yaml}";
                    "https://raw.githubusercontent.com/argoproj/argo-workflows/master/api/jsonschema/schema.json" =
                      "*flow*.{yml,yaml}";
                  };
                };
              };
              file_types = {
                Helm = [
                  "**/templates/**/*.tpl"
                  "**/templates/**/*.yaml"
                  "**/templates/**/*.yml"
                  "**/helmfile.d/**/*.yaml"
                  "**/helmfile.d/**/*.yml"
                ];
                Ansible = [
                  "roles/*/{tasks,handlers,defaults,vars}/*.{yml,yaml}"
                  "{group_vars,host_vars}/**/*.{yml,yaml}"
                  "*playbook*.{yml,yaml}"
                ];
              };
            };
          };
        };
      };
    };
  };
}
