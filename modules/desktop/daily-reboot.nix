# Daily reboot at 3:00 a.m. UTC
{
  pkgs,
  ...
}:
{
  systemd.timers.daily-reboot = {
    description = "Reboot the machine every day at 3:00 a.m. UTC";
    timerConfig = {
      OnCalendar = "*-*-* 03:00:00 UTC";
      Persistent = true;
    };
    wantedBy = [ "timers.target" ];
  };

  systemd.services.daily-reboot = {
    description = "Reboot the machine";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl reboot";
    };
  };
}
