{ config, lib, pkgs, ... }:

let
  cfg = config.modules.system.audio;

  # The sink the filter chain adds; the WirePlumber script finds it by name.
  filterNode = "speaker-filter";
in
{
  options = {
    modules = {
      system = {
        audio = {
          enable = lib.mkEnableOption "PipeWire audio";

          speakers = {
            enable = lib.mkEnableOption "a correction filter on the built-in speakers only";

            # No defaults: names differ per machine (wpctl inspect).
            card = lib.mkOption {
              type = lib.types.str;
              example = "alsa_card.pci-0000_06_00.6";
              description = "device.name of the sound card the speakers are on.";
            };

            sink = lib.mkOption {
              type = lib.types.str;
              example = "alsa_output.pci-0000_06_00.6.analog-stereo";
              description = "node.name of that card's output.";
            };

            route = lib.mkOption {
              type = lib.types.str;
              default = "analog-output-speaker";
              description = "the speakers' route on that output; any other (headphones) bypasses the filter.";
            };

            impulseResponse = lib.mkOption {
              type = lib.types.path;
              description = "stereo WAV with the FIR that corrects the speakers.";
            };
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    security = {
      rtkit = {
        enable = true;
      };
    };

    services = {
      pulseaudio = {
        enable = false;
      };

      pipewire = {
        enable = true;
        pulse = {
          enable = true;
        };
        alsa = {
          enable = true;
          support32Bit = true;
        };
        jack = {
          enable = false;
        };

        extraLv2Packages = lib.mkIf cfg.speakers.enable [
          pkgs.calf
          pkgs.lsp-plugins
        ];

        # The FIR, then what Nahimic's default Music profile adds on Windows
        # (voice +4, treble +4, virtual bass +6), then a limiter for the
        # peaks the boosts push over 0 dB. Ported from an EasyEffects preset,
        # hence the same Calf and LSP plugins and settings.
        extraConfig = lib.mkIf cfg.speakers.enable {
          pipewire = {
            "60-speaker-filter" = {
              "context.modules" = [
                {
                  name = "libpipewire-module-filter-chain";
                  # A plugin that fails to load costs the filter, not the
                  # whole PipeWire daemon.
                  flags = [ "nofail" ];
                  args = {
                    "node.description" = "Speaker filter";
                    "media.name" = "Speaker filter";
                    "filter.graph" = {
                      nodes = [
                        {
                          type = "builtin";
                          name = "fir_l";
                          label = "convolver";
                          config = {
                            filename = "${cfg.speakers.impulseResponse}";
                            channel = 0;
                          };
                        }
                        {
                          type = "builtin";
                          name = "fir_r";
                          label = "convolver";
                          config = {
                            filename = "${cfg.speakers.impulseResponse}";
                            channel = 1;
                          };
                        }
                        {
                          type = "builtin";
                          name = "voice_l";
                          label = "bq_peaking";
                          control = {
                            Freq = 1400.0;
                            Q = 0.47;
                            Gain = 4.0;
                          };
                        }
                        {
                          type = "builtin";
                          name = "voice_r";
                          label = "bq_peaking";
                          control = {
                            Freq = 1400.0;
                            Q = 0.47;
                            Gain = 4.0;
                          };
                        }
                        {
                          type = "builtin";
                          name = "treble_l";
                          label = "bq_highshelf";
                          control = {
                            Freq = 8000.0;
                            Q = 0.707;
                            Gain = 4.0;
                          };
                        }
                        {
                          type = "builtin";
                          name = "treble_r";
                          label = "bq_highshelf";
                          control = {
                            Freq = 8000.0;
                            Q = 0.707;
                            Gain = 4.0;
                          };
                        }
                        {
                          type = "lv2";
                          name = "bass";
                          plugin = "http://calf.sourceforge.net/plugins/BassEnhancer";
                          control = {
                            amount = 1.995; # +6 dB
                            drive = 8.5;
                            freq = 160.0;
                            floor = 20.0;
                            floor_active = 0;
                            blend = 0.0;
                          };
                        }
                        {
                          type = "lv2";
                          name = "limiter";
                          plugin = "http://lsp-plug.in/plugins/lv2/limiter_stereo";
                          # Off by default in EasyEffects, on in the plugin:
                          # boost (makeup gain) and alr (auto level).
                          control = {
                            th = 0.891; # -1 dB
                            lk = 5.0;
                            at = 5.0;
                            rt = 20.0;
                            mode = 0;
                            ovs = 0;
                            dith = 0;
                            boost = 0;
                            alr = 0;
                          };
                        }
                      ];
                      links = [
                        {
                          output = "fir_l:Out";
                          input = "voice_l:In";
                        }
                        {
                          output = "fir_r:Out";
                          input = "voice_r:In";
                        }
                        {
                          output = "voice_l:Out";
                          input = "treble_l:In";
                        }
                        {
                          output = "voice_r:Out";
                          input = "treble_r:In";
                        }
                        {
                          output = "treble_l:Out";
                          input = "bass:in_l";
                        }
                        {
                          output = "treble_r:Out";
                          input = "bass:in_r";
                        }
                        {
                          output = "bass:out_l";
                          input = "limiter:in_l";
                        }
                        {
                          output = "bass:out_r";
                          input = "limiter:in_r";
                        }
                      ];
                      inputs = [
                        "fir_l:In"
                        "fir_r:In"
                      ];
                      outputs = [
                        "limiter:out_l"
                        "limiter:out_r"
                      ];
                    };
                    # A smart filter: WirePlumber puts it in front of the
                    # speakers' sink for whatever plays there, and keeps
                    # that sink the default and its volume the one in use.
                    "capture.props" = {
                      "node.name" = filterNode;
                      "media.class" = "Audio/Sink";
                      "audio.position" = [
                        "FL"
                        "FR"
                      ];
                      "filter.smart" = true;
                      "filter.smart.name" = filterNode;
                      "filter.smart.target" = {
                        "node.name" = cfg.speakers.sink;
                      };
                    };
                    "playback.props" = {
                      "node.name" = "${filterNode}.output";
                      "node.passive" = true;
                      "audio.position" = [
                        "FL"
                        "FR"
                      ];
                      "stream.dont-remix" = true;
                    };
                  };
                }
              ];
            };
          };
        };

        wireplumber = {
          enable = true;
          extraScripts = lib.mkIf cfg.speakers.enable {
            "speaker-filter.lua" = builtins.readFile ./speaker-filter.lua;
          };
          extraConfig = {
            "50-bluetooth-hfp" = {
              "wireplumber.settings" = {
                "bluetooth.autoswitch-to-headset-profile" = false;
              };
            };
          };
          # Written by hand, not through extraConfig: WirePlumber keeps the
          # quotes of names in wants/requires arrays, and the JSON that
          # extraConfig writes quotes every string. The script is wanted
          # rather than required for the same reason as nofail above: a
          # broken script must not stop WirePlumber.
          configPackages = lib.mkIf cfg.speakers.enable [
            (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/60-speaker-filter.conf" ''
              wireplumber.components = [
                {
                  name = speaker-filter.lua, type = script/lua
                  arguments = {
                    device.name = "${cfg.speakers.card}"
                    filter.node.name = "${filterNode}"
                    route = "${cfg.speakers.route}"
                  }
                  provides = custom.speaker-filter.script
                }
                {
                  type = virtual, provides = custom.speaker-filter
                  wants = [ custom.speaker-filter.script ]
                }
              ]

              wireplumber.profiles = {
                main = {
                  custom.speaker-filter = required
                }
              }
            '')
          ];
        };
      };
    };
  };
}
