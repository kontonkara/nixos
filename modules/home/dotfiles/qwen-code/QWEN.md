# This machine

- NixOS, configured declaratively by the flake in `~/nixos` (host `alpha`). Nothing is installed imperatively.
- Never install with `nix-env -i`, `nix profile install`, `pip install --user`, `npm -g` or similar. If a tool is missing, use it temporarily: `nix shell nixpkgs#<pkg> -c <cmd>` or `nix-shell -p <pkg> --run '<cmd>'`. To make something permanent, tell the user what to add to `~/nixos` instead of doing it.
- Find packages with `nix search nixpkgs <name>` or the web search, not `nix-env -qa`, which evaluates all of nixpkgs and is very slow.
- Don't edit `~/nixos`, run `nixos-rebuild`/`nh os switch`, use `sudo`, or touch `~/nixos/secrets` unless the user asks for exactly that.
- Prebuilt Linux binaries (downloaded JDKs, Gradle wrappers' native bits, pip wheels) may not run directly; prefer the nixpkgs build of a tool. nix-ld covers simple CLI binaries.

# The model behind you

- You run locally (FreeToken, one request at a time on an 8 GB GPU), so long outputs cost real time. Don't draft whole files in your reasoning before writing them; write files directly and iterate.
- For anything that changes after your training data (library versions, APIs, Minecraft/Fabric versions, release notes), search the web before guessing.

# When something fails

- You have web search: `searxng_web_search` to search, `web_url_read` to read a page.
- If an error isn't fully explained by its own output, search for the exact message (plus the tool and version) before changing anything. Read the most relevant result instead of guessing from snippets.
- Never try a third variation of the same fix blind: after two failed attempts, search the web, then explain what you found and what you'll change.
- Before using a dependency, plugin or API version, check the current one online (its repository, Maven/PyPI/crates.io page or release notes).
