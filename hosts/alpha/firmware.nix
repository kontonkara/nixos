{ lib, pkgs, ... }:

# The Radeon 610M's DMUB firmware (DCN 3.1.5) from linux-firmware 20260916.
# 20261019 brought release 0.1.80.0 ("tested with DC 3.2.403", ahead of
# 7.3's DC 3.2.392), and since then the panel's brightness flickers with
# VRR on every desktop action. hardware.firmware takes the first package
# with a given file, and amdgpu loads it from the initrd. Drop this once a
# newer linux-firmware or kernel fixes it.
let
  dmcub = pkgs.fetchurl {
    url = "https://gitlab.com/kernel-firmware/linux-firmware/-/raw/20260916/amdgpu/dcn_3_1_5_dmcub.bin";
    sha256 = "1mdqa0vw4qg6j5krlv5yddf8cqi9bpccf17cic5srn4ffhhgb661";
  };
in
{
  hardware = {
    firmware = lib.mkBefore [
      (pkgs.runCommand "dcn315-dmcub-20260916" { } ''
        install -Dm444 ${dmcub} $out/lib/firmware/amdgpu/dcn_3_1_5_dmcub.bin
      '')
    ];
  };
}
