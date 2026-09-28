{ config, lib, pkgs, inputs, username, ... }:

let
  cfg = config.modules.home.obsidian;

  hmConfig = config.home-manager.users.${username};
  hmStylix = hmConfig.stylix;

  # stylix's target fills programs.obsidian.defaultSettings (fonts and the
  # palette snippet with the accent), but those only reach vaults declared in
  # programs.obsidian.vaults, as read-only store links. Obsidian has to keep
  # appearance.json writable, and vaults are made in the app, so the
  # activation below copies them into every vault it knows instead.
  stylixSettings = hmConfig.programs.obsidian.defaultSettings;
  snippet = lib.head stylixSettings.cssSnippets;

  appearance = pkgs.writeText "obsidian-appearance.json" (
    builtins.toJSON {
      inherit (stylixSettings.appearance) interfaceFontFamily monospaceFontFamily;
      # stylix passes its point size, but Obsidian reads pixels.
      baseFontSize = (stylixSettings.appearance.baseFontSize * 4 + 1) / 3;
      # The snippet only styles the matching light or dark base theme.
      theme = if hmStylix.polarity == "light" then "moonstone" else "obsidian";
      # The default theme: a community theme would repaint over the snippet.
      cssTheme = "";
      accentColor = hmConfig.lib.stylix.colors.withHashtag.${config.modules.home.stylix.accent};
    }
  );
in
{
  options = {
    modules = {
      home = {
        obsidian = {
          enable = lib.mkEnableOption "obsidian";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager = {
      users = {
        ${username} = {
          programs = {
            obsidian = {
              enable = true;
            };
          };

          # For every vault in obsidian.json: the snippet as a plain file, and
          # these keys merged into appearance.json with the snippet enabled.
          # Obsidian may need a restart to pick up a change made while it runs.
          home = {
            activation = {
              obsidianStylix = lib.mkIf (hmStylix.enable && hmStylix.targets.obsidian.enable) (
                inputs.home-manager.lib.hm.dag.entryAfter [ "obsidian" ] ''
                  obsidianConfig="${hmConfig.xdg.configHome}/obsidian/obsidian.json"
                  if [ -f "$obsidianConfig" ]; then
                    ${lib.getExe pkgs.jq} -r '.vaults[]?.path' "$obsidianConfig" | while IFS= read -r vault; do
                      [ -d "$vault" ] || continue
                      settings="$vault/.obsidian"
                      run mkdir -p "$settings/snippets"
                      run install -m644 ${pkgs.writeText "stylix.css" snippet.text} "$settings/snippets/${snippet.name}.css"

                      current="$settings/appearance.json"
                      [ -f "$current" ] || current=${pkgs.writeText "empty.json" "{}"}
                      merged="$(mktemp)"
                      ${lib.getExe pkgs.jq} --slurpfile stylix ${appearance} \
                        '. * $stylix[0] | .enabledCssSnippets = ((.enabledCssSnippets // []) + ["${snippet.name}"] | unique)' \
                        "$current" > "$merged"
                      run install -m644 "$merged" "$settings/appearance.json"
                      rm -f "$merged"
                    done
                  fi
                ''
              );
            };
          };
        };
      };
    };
  };
}
