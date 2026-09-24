{
  config,
  lib,
  pkgs,
  inputs,
  username,
  ...
}:

let
  cfg = config.modules.programs.yandex-browser-corporate;
  appId = "ru.yandex.Browser.Corporate";
  hm = config.home-manager.users.${username} or null;

  # hardware.nvidia.prime bus IDs are "PCI:bus:device:function" in decimal,
  # optionally "PCI:bus@domain:device:function"; /dev/dri/by-path wants hex.
  busIdToRenderNode =
    busId:
    let
      parts = lib.splitString ":" busId;
      busAndDomain = lib.splitString "@" (lib.elemAt parts 1);
      bus = lib.head busAndDomain;
      domain = if lib.length busAndDomain > 1 then lib.elemAt busAndDomain 1 else "0";
      hex =
        width: value:
        lib.fixedWidthString width "0" (lib.toLower (lib.toHexString (lib.toInt value)));
    in
    "/dev/dri/by-path/pci-${hex 4 domain}:${hex 2 bus}:${hex 2 (lib.elemAt parts 2)}.${hex 1 (lib.elemAt parts 3)}-render";

  prime = config.hardware.nvidia.prime;
  primaryGpuBusId =
    if prime.amdgpuBusId != "" then
      prime.amdgpuBusId
    else if prime.intelBusId != "" then
      prime.intelBusId
    else
      null;

  # Home Manager settings that may be absent or partially set.
  hmIconTheme =
    if hm != null && hm.gtk.enable && hm.gtk.iconTheme != null then hm.gtk.iconTheme.package else null;
  hmCursor =
    if hm != null && hm.home.pointerCursor != null && (hm.home.pointerCursor.enable or true) then
      hm.home.pointerCursor.package
    else
      null;
  hmDownloadDir =
    if hm != null && hm.xdg.userDirs.enable && hm.xdg.userDirs.download != null then
      hm.xdg.userDirs.download
    else
      "$HOME/Downloads";

  # The session's graphics drivers without NVIDIA's: the browser stays on
  # the Mesa GPU and never loads the userspace driver of the discrete one.
  graphicsDriver = pkgs.buildEnv {
    name = "yandex-browser-graphics-drivers";
    paths = [
      config.hardware.graphics.package
    ]
    ++ lib.filter (
      driver: !lib.hasInfix "nvidia" (lib.getName driver)
    ) config.hardware.graphics.extraPackages;
  };

  package = import ../../../pkgs/yandex-browser-corporate {
    inherit pkgs appId;
    inherit (inputs) nixpak;
    inherit (cfg)
      keyStorage
      migrateFromKeyring
      extraManagedPolicies
      extraRootCertificates
      renderNode
      extraFonts
      isolateNetwork
      ;
    licenseSeedPath = cfg.licenseSecretPath;
    extraArgs = cfg.extraCommandLineArgs;
    inherit graphicsDriver;
    fontconfigEtc =
      if config.fonts.fontconfig.enable then config.environment.etc.fonts.source else null;
    iconThemes = lib.optional (hmIconTheme != null) hmIconTheme;
    cursorThemes = lib.optional (hmCursor != null) hmCursor;
    downloadDir = hmDownloadDir;
    timeZone = config.time.timeZone;
  };
in
{
  options = {
    modules = {
      programs = {
        yandex-browser-corporate = {
          enable = lib.mkEnableOption "corporate yandex browser in a nixpak sandbox";

          licenseSecretPath = lib.mkOption {
            type = lib.types.str;
            default = "/run/secrets/yandex-browser";
            description = ''
              Read-only seed for the corporate license (sops-nix path). Seeded into
              the browser profile on first launch; the browser rotates the live
              copy afterwards. After rotating the sops secret, reseed with
              `YANDEX_LICENSE_RESEED=1 yandex-browser-corporate`.
            '';
          };

          keyStorage = lib.mkOption {
            type = lib.types.enum [
              "portal"
              "keyring"
              "basic"
            ];
            default = "portal";
            description = ''
              Where Chromium keeps the key that encrypts cookies, passwords and
              card data. `portal` derives a per-app key through the xdg Secret
              portal (gnome-keyring), so the sandbox never sees the login
              keyring; `keyring` talks to the Secret Service directly (the whole
              keyring is reachable); `basic` uses Chromium's fixed key.
            '';
          };

          migrateFromKeyring = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = ''
              With `keyStorage = "portal"`, still let the browser read data
              encrypted by the old keyring key. Cookies are re-encrypted only
              when they change, so turn this off again once migrated.
            '';
          };

          isolateNetwork = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = ''
              Give the browser its own network namespace (pasta): the internet
              and LAN work, services on the host's loopback do not.
            '';
          };

          renderNode = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = lib.mapNullable busIdToRenderNode primaryGpuBusId;
            defaultText = lib.literalMD "the PRIME iGPU's render node, if PRIME is configured";
            example = "/dev/dri/by-path/pci-0000:06:00.0-render";
            description = ''
              The only GPU the sandbox gets. The default keeps the browser on
              the integrated GPU so it never wakes the discrete one; null
              exposes all of /dev/dri.
            '';
          };

          extraFonts = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            default = lib.optional (
              hm != null && hm.gtk.enable && hm.gtk.font != null && (hm.gtk.font.package or null) != null
            ) hm.gtk.font.package;
            defaultText = lib.literalMD "the home-manager GTK font";
            description = "Fonts on top of the system's fontconfig set.";
          };

          extraRootCertificates = lib.mkOption {
            type = lib.types.listOf lib.types.path;
            default = [ ../../../pkgs/yandex-browser-corporate/YandexInternalRootCA.pem ];
            description = ''
              PEM roots trusted by the browser only (its own NSS database). The
              default is Yandex's internal root, which the corporate security
              extension and event connector hosts chain to.
            '';
          };

          extraCommandLineArgs = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            example = [ "--force-dark-mode" ];
            description = "Additional arguments passed to every browser process.";
          };

          extraManagedPolicies = lib.mkOption {
            type = lib.types.attrs;
            default = { };
            example = {
              BackgroundModeEnabled = false;
              PromptForDownloadLocation = true;
            };
            description = "Policies merged over the vendor-managed policy set.";
          };

          makeDefaultBrowser = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Use Yandex Browser Corporate for HTML and HTTP(S).";
          };

          package = lib.mkOption {
            type = lib.types.package;
            readOnly = true;
            default = package;
            description = "The resulting sandboxed browser.";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    xdg.mime.defaultApplications = lib.mkIf cfg.makeDefaultBrowser {
      "text/html" = "${appId}.desktop";
      "application/xhtml+xml" = "${appId}.desktop";
      "x-scheme-handler/http" = "${appId}.desktop";
      "x-scheme-handler/https" = "${appId}.desktop";
    };

    xdg.icons.enable = lib.mkDefault true;
    xdg.mime.enable = lib.mkDefault true;
  };
}
