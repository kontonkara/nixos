{ username, pkgs, ... }:

{
  home-manager = {
    users = {
      ${username} = {
        home = {
          packages = [
            pkgs.deadnix
            pkgs.nixd
            pkgs.statix
          ];

          sessionVariables = {
            EDITOR = "code --wait";
            VISUAL = "code --wait";
          };
        };

        programs = {
          vscode = {
            enable = true;
            package = pkgs.vscode.override {
              commandLineArgs = [
                # "--enable-features=UseOzonePlatform"
                "--ozone-platform=x11"
              ];
            };
            mutableExtensionsDir = false;

            argvSettings = {
              "disable-hardware-acceleration" = false;
              "enable-crash-reporter" = false;
              "password-store" = "kwallet";
            };

            profiles = {
              default = {
                enableUpdateCheck = false;
                enableExtensionUpdateCheck = false;

                userSettings = {
                  "breadcrumbs.enabled" = true;
                  "chat.disableAIFeatures" = true;
                  "diffEditor.ignoreTrimWhitespace" = false;
                  "editor.bracketPairColorization.enabled" = true;
                  "editor.cursorBlinking" = "smooth";
                  "editor.cursorSmoothCaretAnimation" = "on";
                  "editor.detectIndentation" = true;
                  "editor.fontLigatures" = true;
                  "editor.formatOnPaste" = false;
                  "editor.formatOnSave" = true;
                  "editor.guides.bracketPairs" = "active";
                  "editor.inlineSuggest.enabled" = true;
                  "editor.minimap.enabled" = false;
                  "editor.rulers" = [
                    100
                    120
                  ];
                  "editor.smoothScrolling" = true;
                  "editor.stickyScroll.enabled" = true;
                  "editor.tabSize" = 2;
                  "editor.wordWrap" = "on";
                  "errorLens.enabledDiagnosticLevels" = [
                    "error"
                    "warning"
                    "info"
                  ];
                  "explorer.confirmDelete" = true;
                  "explorer.confirmDragAndDrop" = false;
                  "explorer.compactFolders" = false;
                  "explorer.fileNesting.enabled" = true;
                  "explorer.fileNesting.expand" = false;
                  "explorer.fileNesting.patterns" = {
                    ".gitignore" = ".gitattributes, .gitmodules";
                    "flake.nix" = "flake.lock";
                    "package.json" = "package-lock.json,yarn.lock,pnpm-lock.yaml";
                  };
                  "extensions.autoCheckUpdates" = false;
                  "extensions.autoUpdate" = false;
                  "extensions.ignoreRecommendations" = true;
                  "files.autoSave" = "onFocusChange";
                  "files.associations" = {
                    logcat = "logcat";
                  };
                  "files.exclude" = {
                    "**/.direnv" = true;
                    "**/.git" = true;
                    "**/.jj" = true;
                    "**/result" = true;
                    "**/result-*" = true;
                  };
                  "files.insertFinalNewline" = true;
                  "files.trimFinalNewlines" = true;
                  "files.trimTrailingWhitespace" = true;
                  "git.autofetch" = true;
                  "git.confirmSync" = false;
                  "git.enableSmartCommit" = true;
                  "git.terminalAuthentication" = false;
                  "git.useIntegratedAskPass" = false;
                  "github.gitAuthentication" = false;
                  "nix.enableLanguageServer" = true;
                  "nix.serverPath" = "${pkgs.nixd}/bin/nixd";
                  "redhat.telemetry.enabled" = false;
                  "security.workspace.trust.enabled" = true;
                  "security.workspace.trust.untrustedFiles" = "open";
                  "telemetry.telemetryLevel" = "off";
                  "terminal.integrated.defaultProfile.linux" = "fish";
                  "terminal.integrated.cursorBlinking" = true;
                  "terminal.integrated.profiles.linux" = {
                    fish = {
                      path = "${pkgs.fish}/bin/fish";
                    };
                  };
                  "terminal.integrated.smoothScrolling" = true;
                  "update.mode" = "none";
                  "window.commandCenter" = true;
                  "window.controlsStyle" = "default";
                  # "window.customTitleBarVisibility" = "windowed";
                  # "window.dialogStyle" = "custom";
                  "window.titleBarStyle" = "native";
                  "workbench.iconTheme" = "catppuccin-mocha";
                  "workbench.list.smoothScrolling" = true;
                  "workbench.startupEditor" = "none";

                  "[json]" = {
                    "editor.defaultFormatter" = "vscode.json-language-features";
                  };
                  "[jsonc]" = {
                    "editor.defaultFormatter" = "vscode.json-language-features";
                  };
                  "[nix]" = {
                    "editor.formatOnSave" = false;
                    "editor.tabSize" = 2;
                  };
                };

                extensions = with pkgs.vscode-extensions; [
                  catppuccin.catppuccin-vsc-icons
                  github.vscode-github-actions
                  christian-kohler.path-intellisense
                  jnoortheen.nix-ide
                  mkhl.direnv
                  redhat.vscode-yaml
                  tamasfe.even-better-toml
                  usernamehw.errorlens
                ];

                keybindings = [
                  {
                    key = "ctrl+shift+f";
                    command = "workbench.action.findInFiles";
                  }
                  {
                    key = "ctrl+shift+e";
                    command = "workbench.view.explorer";
                  }
                  {
                    key = "ctrl+shift+g";
                    command = "workbench.view.scm";
                  }
                  {
                    key = "ctrl+shift+`";
                    command = "workbench.action.terminal.toggleTerminal";
                  }
                ];
              };
            };
          };
        };
      };
    };
  };
}
