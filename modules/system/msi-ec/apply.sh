# Applies the msi-ec battery charge threshold and the EC modes for the
# current power source. Run by msi-ec-apply.service at boot, on AC
# plug/unplug and whenever the driver binds. Missing sysfs files (driver not
# loaded, EC firmware rejected, feature not exposed) are logged and skipped;
# only rejected reads/writes, or a target this firmware does not offer, make
# the unit fail.
#
# Environment, set by the NixOS module:
#   MSI_EC_CHARGE_THRESHOLD      end threshold in percent; empty = leave alone
#   MSI_EC_MODES                 1 = switch EC modes by power source
#   MSI_EC_{AC,BATTERY}_SHIFT_MODE / _FAN_MODE / _SUPER_BATTERY (on|off)
#   MSI_EC_REARM_TURBO_DELAY     seconds; empty = no comfort->turbo rearm

readonly ec=/sys/devices/platform/msi-ec
readonly supplies=/sys/class/power_supply

status=0

info() {
  printf '%s\n' "$*"
}

# <4>/<3> are sd-daemon priority prefixes, so journalctl -p warning finds them.
warn() {
  printf '<4>%s\n' "$*"
}

fail() {
  printf '<3>%s\n' "$*"
  status=1
}

apply_charge_threshold() {
  local want=$1 path battery before after found=0

  for path in "$supplies"/*/charge_control_end_threshold; do
    [[ -e $path ]] || continue
    battery=${path%/*}
    battery=${battery##*/}
    found=1

    if ! read -r before < "$path"; then
      fail "$battery: cannot read charge_control_end_threshold"
      continue
    fi

    if [[ $before == "$want" ]]; then
      info "$battery: charge threshold already ${want}%"
      continue
    fi

    after=
    if printf '%s\n' "$want" > "$path" && read -r after < "$path" && [[ $after == "$want" ]]; then
      info "$battery: charge threshold ${before}% -> ${want}% (charging resumes below $((want - 10))%)"
    else
      fail "$battery: setting charge threshold ${want}% failed (reads ${after:-nothing})"
    fi
  done

  if ((!found)); then
    warn "no battery exposes charge_control_end_threshold (msi-ec not loaded, or the EC had charge control disabled when it loaded); leaving the threshold alone"
  fi
}

# Prints "ac" if any Mains supply is online, "battery" if all are offline,
# nothing if no Mains supply is registered yet (ac.ko not loaded).
power_source() {
  local supply type online seen=0

  for supply in "$supplies"/*; do
    [[ -r $supply/type && -r $supply/online ]] || continue
    read -r type < "$supply/type" || continue
    [[ $type == Mains ]] || continue
    read -r online < "$supply/online" || continue
    seen=1

    if [[ $online == 1 ]]; then
      printf 'ac'
      return 0
    fi
  done

  if ((seen)); then
    printf 'battery'
  fi
}

# ec_set <attribute> <value> [force]: writes unless the EC already reports
# the value (or force is given), then reads it back. The value is checked
# against available_shift_modes / available_fan_modes where those exist.
ec_set() {
  local attr=$1 want=$2 force=${3:-} path=$ec/$1 modes=$ec/available_$1s before after=

  if [[ ! -e $path ]]; then
    warn "$attr: not exposed by msi-ec for this firmware, skipping"
    return 0
  fi

  if [[ -r $modes ]] && ! grep -qxF -- "$want" "$modes"; then
    fail "$attr: $want is not one of: $(tr '\n' ' ' < "$modes")"
    return 0
  fi

  if ! read -r before < "$path"; then
    fail "$attr: read failed"
    return 0
  fi

  if [[ $before == "$want" && -z $force ]]; then
    info "$attr: already $want"
    return 0
  fi

  if ! printf '%s\n' "$want" > "$path"; then
    fail "$attr: writing $want failed"
    return 0
  fi

  if read -r after < "$path" && [[ $after == "$want" ]]; then
    if [[ $before == "$want" ]]; then
      info "$attr: rewrote $want"
    else
      info "$attr: $before -> $want"
    fi
  else
    fail "$attr: wrote $want but the EC reports ${after:-nothing}"
  fi
}

apply_modes() {
  local power shift_mode fan_mode super_battery

  if [[ ! -d $ec ]]; then
    warn "$ec is missing (msi-ec not loaded or it rejected this EC firmware); leaving EC modes alone"
    return 0
  fi

  power=$(power_source)

  case $power in
    ac)
      shift_mode=${MSI_EC_AC_SHIFT_MODE:?}
      fan_mode=${MSI_EC_AC_FAN_MODE:?}
      super_battery=${MSI_EC_AC_SUPER_BATTERY:?}
      ;;
    battery)
      shift_mode=${MSI_EC_BATTERY_SHIFT_MODE:?}
      fan_mode=${MSI_EC_BATTERY_FAN_MODE:?}
      super_battery=${MSI_EC_BATTERY_SUPER_BATTERY:?}
      ;;
    *)
      warn "no Mains power supply registered yet, cannot tell AC from battery; leaving EC modes alone"
      return 0
      ;;
  esac

  info "on $power: shift_mode=$shift_mode fan_mode=$fan_mode super_battery=$super_battery"

  if [[ $power == ac && $shift_mode == turbo && -n ${MSI_EC_REARM_TURBO_DELAY:-} ]]; then
    # Unverified observation on this EC (17KKIMS1.115), never upstreamed:
    # turbo on AC did not always take effect until the EC was cycled through
    # comfort first. The read-back cannot detect it, hence the blind rearm.
    info "rearming turbo through comfort"
    ec_set shift_mode comfort force
    ec_set fan_mode auto force
    ec_set super_battery off force
    sleep "$MSI_EC_REARM_TURBO_DELAY"
    ec_set shift_mode "$shift_mode" force
    ec_set fan_mode "$fan_mode" force
    ec_set super_battery "$super_battery" force
  elif [[ $power == ac ]]; then
    # Leave super-battery before raising the shift mode ...
    ec_set super_battery "$super_battery"
    ec_set fan_mode "$fan_mode"
    ec_set shift_mode "$shift_mode"
  else
    # ... and lower the shift mode before entering it.
    ec_set shift_mode "$shift_mode"
    ec_set fan_mode "$fan_mode"
    ec_set super_battery "$super_battery"
  fi
}

if [[ -r $ec/fw_version ]] && read -r firmware < "$ec/fw_version"; then
  info "msi-ec: EC firmware $firmware"
fi

if [[ -n ${MSI_EC_CHARGE_THRESHOLD:-} ]]; then
  apply_charge_threshold "$MSI_EC_CHARGE_THRESHOLD"
fi

if [[ ${MSI_EC_MODES:-0} == 1 ]]; then
  apply_modes
fi

exit "$status"
