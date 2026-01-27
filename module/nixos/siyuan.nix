{ config, lib, ... }:

let
  cfg = config.custom.siyuan;
in
{
  options.custom.siyuan = {
    enable = lib.mkEnableOption "SiYuan Note Server";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.podman.enable = true;

    sops.secrets.siyuan = { };
    sops.templates."siyuan.env".content = ''
      SIYUAN_ACCESS_AUTH_CODE=${config.sops.placeholder.siyuan}
    '';

    virtualisation.oci-containers.containers.siyuan = {
      image = "b3log/siyuan";
      ports = [ "6806:6806" ];
      volumes = [
        "/var/lib/siyuan:/siyuan/workspace"
      ];
      cmd = [ "--workspace=/siyuan/workspace" ];
      environment = {
        TZ = "America/Chicago";
      };
      environmentFiles = [ config.sops.templates."siyuan.env".path ];
    };
    systemd.tmpfiles.rules = [
      "d /var/lib/siyuan 0755 1000 1000 -"
    ];

    networking.firewall.allowedTCPPorts = [ 6806 ];

    systemd.targets.sleep.enable = false;
    systemd.targets.suspend.enable = false;
    systemd.targets.hibernate.enable = false;
    systemd.targets.hybrid-sleep.enable = false;

    services.logind = {
      lidSwitch = "ignore";
      settings.Login = {
        IdleAction = "ignore";
        HandleSuspendKey = "ignore";
        HandleHibernateKey = "ignore";
      };
    };
  };
}
