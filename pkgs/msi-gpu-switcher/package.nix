{
  buildGoModule,
  fetchFromGitHub,
  lib,
}:

buildGoModule rec {
  pname = "msi-gpu-switcher";
  version = "0.1.5";

  src = fetchFromGitHub {
    owner = "ElXreno";
    repo = "msi-gpu-switcher";
    tag = "v${version}";
    hash = "sha256-z63byPcgKGp+WiRkrhDhqSSnjAnamswU+MypQ4mD580=";
  };

  vendorHash = "sha256-loaEr1mX4T1MwfuNiQYByxeSa7qEmaH7EZ2nCdD0AY8=";

  meta = {
    description = "Minimal GPU MUX switcher for MSI laptops";
    homepage = "https://github.com/ElXreno/msi-gpu-switcher";
    license = lib.licenses.mit;
    mainProgram = "msi-gpu-switcher";
    platforms = lib.platforms.linux;
  };
}
