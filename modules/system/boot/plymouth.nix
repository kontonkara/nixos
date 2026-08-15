{ config, lib, ... }:

{
  config = lib.mkIf config.modules.boot.enable {
    boot = {
      plymouth = {
        enable = true;
      };
    };
  };
}
