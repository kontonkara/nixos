{ config, lib, pkgs, username, ... }:

let
  cfg = config.modules.home.zed;

  zedPatched =
    (pkgs.zed-editor.override {
      # Only needed on machines other Zed clients connect to.
      buildRemoteServer = false;
    }).overrideAttrs
      (old: {
        patches = (old.patches or [ ]) ++ [
          # Cursor animation is upstream since 1.20 (`cursor_animation`).
          ./patches/smooth-scroll.patch
        ];
        # The check phase compiles most of the workspace a second time (with
        # test-support features) only to run the `zed` crate's own tests.
        doCheck = false;
      });

  # Zed (wgpu/Vulkan) already picks the compositor's GPU, but enumerating
  # adapters loads every Vulkan ICD, and the NVIDIA one pulls the RTX out of
  # D3cold. An inherited __NV_PRIME_RENDER_OFFLOAD=1 would still load the
  # NVIDIA optimus layer (and NVIDIA's EGL), so it is reset too.
  zed = pkgs.symlinkJoin {
    name = "zed-editor-igpu-${lib.getVersion zedPatched}";
    paths = [
      zedPatched
    ];
    nativeBuildInputs = [
      pkgs.makeWrapper
    ];
    postBuild = ''
      rm $out/bin/zeditor
      makeWrapper ${lib.getExe zedPatched} $out/bin/zeditor \
        --set VK_LOADER_DRIVERS_DISABLE '*nvidia*' \
        --set __NV_PRIME_RENDER_OFFLOAD 0
    '';
  };
in
{
  options = {
    modules = {
      home = {
        zed = {
          enable = lib.mkEnableOption "zed editor home configuration";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            zed-editor = {
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

              extraPackages = [
                pkgs.ansible-language-server
                pkgs.ansible-lint
                pkgs.crates-lsp
                pkgs.delve
                pkgs.gitlab-ci-ls
                pkgs.golangci-lint
                pkgs.golangci-lint-langserver
                pkgs.gopls
                pkgs.helm-ls
                pkgs.kubernetes-helm
                pkgs.nixd
                pkgs.nixfmt
                pkgs.opentofu
                pkgs.package-version-server
                pkgs.taplo
                pkgs.terraform-ls
                pkgs.vscode-json-languageserver
                pkgs.yaml-language-server
              ];

              userSettings = {
                autosave = "on_focus_change";
                base_keymap = "VSCode";
                buffer_font_features = {
                  calt = true;
                  liga = true;
                };
                colorize_brackets = true;
                cursor_animation = {
                  enabled = true;
                };
                cursor_blink = true;
                diagnostics = {
                  inline = {
                    enabled = true;
                  };
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
                  "..."
                  "**/.direnv"
                  "**/result"
                  "**/result-*"
                ];
                minimap = {
                  show = "never";
                };
                remove_trailing_whitespace_on_save = true;
                restore_on_startup = "empty_tab";
                wrap_guides = [
                  100
                  120
                ];
                show_wrap_guides = true;
                # From patches/smooth-scroll.patch.
                smooth_scroll = {
                  enabled = true;
                };
                soft_wrap = "editor_width";
                sticky_scroll = {
                  enabled = true;
                };
                tab_size = 2;
                title_bar = {
                  show_sign_in = false;
                };
                project_panel = {
                  dock = "left";
                };
                outline_panel = {
                  dock = "left";
                };
                agent = {
                  dock = "left";
                };
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
                  env = {
                    # Empty disables the loader filter again, so Vulkan apps
                    # started from Zed's terminal still see the RTX.
                    VK_LOADER_DRIVERS_DISABLE = "";
                  };
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
                  Terraform = {
                    language_servers = [
                      "terraform-ls"
                    ];
                  };
                };
                lsp = {
                  helm_ls = {
                    settings = {
                      helm-ls = {
                        logLevel = "info";
                        yamlls = {
                          enabled = true;
                        };
                      };
                    };
                  };
                  yaml-language-server = {
                    settings = {
                      yaml = {
                        schemas = {
                          kubernetes = "templates/*.yaml";
                          "https://json.schemastore.org/github-workflow" = ".github/workflows/*";
                          "https://json.schemastore.org/github-action" = ".github/action.{yml,yaml}";
                          "https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/ansible.json#/$defs/tasks" =
                            "roles/*/{tasks,handlers}/*.{yml,yaml}";
                          "https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/vars.json" =
                            "roles/*/{defaults,vars}/*.{yml,yaml}";
                          "https://json.schemastore.org/prettierrc" = ".prettierrc.{yml,yaml}";
                          "https://json.schemastore.org/kustomization" = "kustomization.{yml,yaml}";
                          "https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/ansible.json#/$defs/playbook" =
                            "*play*.{yml,yaml}";
                          "https://json.schemastore.org/chart" = "Chart.{yml,yaml}";
                          "https://www.schemastore.org/dependabot-2.0.json" = ".github/dependabot.{yml,yaml}";
                          "https://gitlab.com/gitlab-org/gitlab-foss/-/raw/master/app/assets/javascripts/editor/schema/ci.json" =
                            "*gitlab-ci*.{yml,yaml}";
                          "https://spec.openapis.org/oas/3.1/schema/2025-09-15" = "*api*.{yml,yaml}";
                          "https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json" =
                            "*docker-compose*.{yml,yaml}";
                          "https://raw.githubusercontent.com/argoproj/argo-workflows/master/api/jsonschema/schema.json" =
                            "*flow*.{yml,yaml}";
                        };
                      };
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
  };
}
