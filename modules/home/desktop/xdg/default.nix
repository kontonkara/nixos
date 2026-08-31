{
  config,
  lib,
  username,
  ...
}:

let
  cfg = config.modules.home.xdg;

  browser = "firefox.desktop";
  code = "code.desktop";
  codeUrlHandler = "code-url-handler.desktop";
  dolphin = "org.kde.dolphin.desktop";
  ark = "org.kde.ark.desktop";
  gwenview = "org.kde.gwenview.desktop";
  keepassxc = "org.keepassxc.KeePassXC.desktop";
  okular = "okularApplication_pdf.desktop";
  telegram = "org.telegram.desktop.desktop";

  browserTypes = [
    "application/xhtml+xml"
    "text/html"
    "x-scheme-handler/http"
    "x-scheme-handler/https"
  ];

  codeTypes = [
    "application/javascript"
    "application/json"
    "application/toml"
    "application/x-shellscript"
    "application/x-yaml"
    "application/xml"
    "text/css"
    "text/csv"
    "text/javascript"
    "text/markdown"
    "text/plain"
    "text/x-cmake"
    "text/x-diff"
    "text/x-nix"
    "text/x-python"
    "text/x-rust"
    "text/x-shellscript"
    "text/x-toml"
    "text/x-typescript"
    "text/yaml"
  ];

  imageTypes = [
    "image/avif"
    "image/bmp"
    "image/gif"
    "image/jpeg"
    "image/png"
    "image/svg+xml"
    "image/tiff"
    "image/webp"
  ];

  archiveTypes = [
    "application/gzip"
    "application/vnd.rar"
    "application/x-7z-compressed"
    "application/x-bzip2"
    "application/x-compressed-tar"
    "application/x-rar-compressed"
    "application/x-tar"
    "application/x-xz"
    "application/zip"
    "application/zstd"
  ];

  defaultApplications =
    lib.genAttrs browserTypes (_: browser)
    // lib.genAttrs codeTypes (_: code)
    // lib.genAttrs imageTypes (_: gwenview)
    // lib.genAttrs archiveTypes (_: ark)
    // {
      "application/epub+zip" = "okularApplication_epub.desktop";
      "application/pdf" = okular;
      "application/vnd.comicbook+zip" = "okularApplication_comicbook.desktop";
      "application/x-cb7" = "okularApplication_comicbook.desktop";
      "application/x-cbr" = "okularApplication_comicbook.desktop";
      "application/x-cbt" = "okularApplication_comicbook.desktop";
      "application/x-cbz" = "okularApplication_comicbook.desktop";
      "application/x-keepass2" = keepassxc;
      "inode/directory" = dolphin;
      "x-scheme-handler/tg" = telegram;
      "x-scheme-handler/vscode" = codeUrlHandler;
    };
in
{
  options.modules.home.xdg.enable = lib.mkEnableOption "XDG desktop integration";

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          xdg = {
            enable = true;

            configFile = {
              "autostart/MControlCenter.desktop".text = ''
                [Desktop Entry]
                Categories=System
                Comment=Tool to change the settings of MSI laptops running Linux
                Exec=mcontrolcenter
                Icon=mcontrolcenter
                Name=MControlCenter
                Type=Application
                Version=1.5
                X-GNOME-Autostart-enabled=true
              '';
              "mimeapps.list".force = true;
            };

            mimeApps = {
              enable = true;
              associations.added = defaultApplications;
              inherit defaultApplications;
            };

            userDirs = {
              enable = true;
              createDirectories = true;
              setSessionVariables = true;

              desktop = "$HOME/desktop";
              documents = "$HOME/documents";
              download = "$HOME/downloads";
              music = "$HOME/music";
              pictures = "$HOME/pictures";
              projects = "$HOME/projects";
              publicShare = "$HOME/public";
              templates = "$HOME/templates";
              videos = "$HOME/videos";

              extraConfig.XDG_SCREENSHOTS_DIR = "$HOME/pictures/screenshots";
            };
          };
        };
      };
    };
  };
}
