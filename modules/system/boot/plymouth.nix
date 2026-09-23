{ config, lib, ... }:

{
  config = lib.mkIf config.modules.system.boot.enable {
    boot = {
      plymouth = {
        enable = true;
      };
    };
  };
}
