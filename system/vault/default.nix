{
  config,
  lib,
  pkgs,
  ...
}:

let
  appRoleCredDir = "/var/lib/vault-agent/auth";
  certOutputDir = "/var/lib/vault-agent/certs";
  certsEnabled = lib.any (c: c.enable) (lib.attrValues config.custom.vault.certs);
  roleIdPath = "${appRoleCredDir}/role_id";
  secretIdPath = "${appRoleCredDir}/secret_id";
  secretIdAccessorPath = "${appRoleCredDir}/secret_id_accessor";


  mkRotationScript = import ./mk-rotation-script.nix { inherit lib pkgs; };
  rotationScript = mkRotationScript { inherit roleIdPath secretIdPath secretIdAccessorPath; };

in
{
  options.custom.vault.certs = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { hostName, ... }:
        {
          options = {
            enable = lib.mkEnableOption "certificate managed by HashiCorp Vault.";

            hostnames = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "Hostnames (Subject Alternative Names) for the certificate. The first name is used as the CN.";
              default = [ ];
            };

            certificatePath = lib.mkOption {
              type = lib.types.str;
              readOnly = true;
              default = "${certOutputDir}/${hostName}.crt";
            };
            keyPath = lib.mkOption {
              type = lib.types.str;
              readOnly = true;
              default = "${certOutputDir}/${hostName}.key";
            };

            pkiRoleName = lib.mkOption {
              type = lib.types.str;
              internal = true;
              default = "${hostName}-role";
            };
          };

          config = lib.mkIf config.enable {
            hostnames = lib.mkIf (config.hostnames == [ ]) (
              lib.fail "The 'hostnames' option for custom.vault.certs.${hostName} must not be empty."
            );
          };
        }
      )
    );
    default = { };
    description = "Declaratively configure server certificates to be issued by Vault PKI.";
  };
  config = lib.mkIf certsEnabled {
    users.users.vault-agent = { isSystemUser = true; group = "vault-agent"; };
    users.groups.vault-agent = {};
    users.groups.nginx = {};
    users.users.nginx.extraGroups = [ "vault-agent" ];

    config.systemd.tmpfiles.rules = [
      "d ${appRoleCredDir} 0750 vault-agent vault-agent -"
      "d ${certOutputDir} 0750 root nginx -"
    ];

    config.systemd.services.vault-secret-id-rotate = {
      description = "Rotate AppRole Secret ID and Revoke Old Credential";
      unitConfig.User = "vault-agent";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${rotationScript}";
      };
    };

    config.systemd.timers.vault-secret-id-rotate = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        RandomizedDelaySec = "1h";
        Persistent = true;
      };
    };


    # 4. Generate Bootstrap Script (The Initial Admin Script)
    environment.systemPackages = [
      bootstrapScript
    ];
  };
}
