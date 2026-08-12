#===============================================================================
# Network watchdog for the desktop
#
# Checks every minute that the desktop still has a working default route and
# link, and restarts NetworkManager after several consecutive failures so the
# machine can be reached remotely again without a physical reboot.
#===============================================================================

{ pkgs, ... }:

let
  watchdogScript = pkgs.writeShellScript "network-watchdog" ''
    set -u

    stateDir="/var/lib/network-watchdog"
    countFile="$stateDir/failures"
    maxFailures=3

    check() {
      IFACE="$(${pkgs.iproute2}/bin/ip route show default | ${pkgs.gawk}/bin/awk '{ print $5; exit }')"

      if [ -z "$IFACE" ]; then
        return 1
      fi

      operstate="$(cat "/sys/class/net/$IFACE/operstate" 2>/dev/null)"
      if [ "$operstate" != "up" ]; then
        return 1
      fi

      GATEWAY="$(${pkgs.iproute2}/bin/ip route show default | ${pkgs.gawk}/bin/awk '{ print $3; exit }')"
      ${pkgs.iputils}/bin/ping -c 1 -W 2 "$GATEWAY" >/dev/null 2>&1
    }

    if check; then
      rm -f "$countFile"
      exit 0
    fi

    count=0
    if [ -f "$countFile" ]; then
      count="$(cat "$countFile")"
    fi
    count=$((count + 1))
    echo "$count" > "$countFile"

    if [ "$count" -ge "$maxFailures" ]; then
      echo "network-watchdog: network down for $count consecutive checks; restarting NetworkManager"
      ${pkgs.systemd}/bin/systemctl restart NetworkManager
      rm -f "$countFile"
    fi
  '';
in
{
  systemd.services.network-watchdog = {
    description = "Check network connectivity and restart NetworkManager if down";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = watchdogScript;
      StateDirectory = "network-watchdog";
      StateDirectoryMode = "0755";
    };
  };

  systemd.timers.network-watchdog = {
    description = "Periodically run the network watchdog";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "1min";
      AccuracySec = "5s";
    };
  };
}
