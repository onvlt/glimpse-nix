{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.programs.glimpse;
in
{
  options.programs.glimpse = {
    enable = lib.mkEnableOption "glimpse";
    package = lib.mkPackageOption pkgs "glimpse" { };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.glimpse-shell = {
      after = [
        "graphical-session.target"
        "glimpse-wallpaper.service"
      ];
      description = "Glimpse shell";
      documentation = [ "https://github.com/alex-oleshkevich/glimpse" ];
      partOf = [ "graphical-session.target" ];
      requisite = [ "graphical-session.target" ];
      startLimitIntervalSec = 60;
      wantedBy = [ "graphical-session.target" ];
      wants = [ "glimpse-wallpaper.service" ];
      environment = { };
      unitConfig = {
        startLimitBurst = 5;
      };
      serviceConfig = {
        Type = "exec";
        ExecStart = "${lib.getExe' cfg.package "glimpse-shell"}";
        Restart = "on-failure";
        RestartSec = 2;
        NoNewPrivileges = "true";
        ProtectKernelTunables = "true";
        ProtectKernelModules = "true";
        ProtectControlGroups = "true";
        LockPersonality = "true";
        RestrictRealtime = "true";
        RestrictSUIDSGID = "true";
      };
    };

    systemd.user.services.glimpse-wallpaper = {
      after = [ "graphical-session.target" ];
      description = "Glimpse wallpaper";
      documentation = [ "https://github.com/alex-oleshkevich/glimpse" ];
      partOf = [ "graphical-session.target" ];
      requisite = [ "graphical-session.target" ];
      startLimitIntervalSec = 60;
      wantedBy = [ "graphical-session.target" ];
      environment = { };
      unitConfig = {
        startLimitBurst = 5;
      };
      serviceConfig = {
        Type = "exec";
        ExecStart = "${lib.getExe' cfg.package "glimpse-wallpaper"}";
        Restart = "on-failure";
        RestartSec = 2;
        NoNewPrivileges = "true";
        ProtectKernelTunables = "true";
        ProtectKernelModules = "true";
        ProtectControlGroups = "true";
        LockPersonality = "true";
        RestrictRealtime = "true";
        RestrictSUIDSGID = "true";
      };
    };

    systemd.user.services.glimpse-lock = {
      after = [ "graphical-session.target" ];
      description = "Glimpse lock screen";
      documentation = [ "https://github.com/alex-oleshkevich/glimpse" ];
      partOf = [ "graphical-session.target" ];
      requisite = [ "graphical-session.target" ];
      startLimitIntervalSec = 60;
      wantedBy = [ "graphical-session.target" ];
      environment = { };
      unitConfig = {
        startLimitBurst = 5;
      };
      serviceConfig = {
        Type = "exec";
        ExecStart = "${lib.getExe' cfg.package "glimpse-lock"}";
        Restart = "always";
        RestartSec = 2;
      };
    };
  };
}
