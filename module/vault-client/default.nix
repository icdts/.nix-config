{ config, pkgs, lib, ... }:
let
  cfg = config.custom.vault;
in
{
  options.custom.vault = {
    enable = lib.mkEnableOption "Vault Agent client";

    serverUrl = lib.mkOption {
      type = lib.types.str;
      description = "URL of the Vault server.";
    };

    roleName = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName;
      description = "The AppRole name for this machine.";
    };

    certs = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          commonName = lib.mkOption { type = lib.types.str; };
          altNames = lib.mkOption { type = lib.types.listOf lib.types.str; default = []; };
          path = lib.mkOption { type = lib.types.str; };
          renewCommand = lib.mkOption {
            type = with lib.types; nullOr str;
            default = null;
            description = "Command to run after certificate is renewed.";
          };
        };
      });
      default = {};
      description = "Declaratively request certificates from Vault.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users."vault-agent" = { isSystemUser = true; group = "vault-agent"; };
    users.groups."vault-agent" = {};

    services.vault-agent.instances.main = {
      enable = true;
      settings = {
        pid_file = "/run/vault-agent-main.pid";
        exit_after_auth = false;
        
        vault = {
          address = cfg.serverUrl;
        };

        auto_auth = {
          method = {
            type = "approle";
            config = {
              role_id_file_path = "/var/lib/vault-agent-main/secrets/role-id";
              secret_id_file_path = "/var/lib/vault-agent-main/secrets/secret-id";
              remove_secret_id_file_after_read = false;
            };
          };
        };

        template = lib.mapAttrsToList (name: cert: {
          destination = cert.path;
          contents = ''
            {{- with pkiCert "default-role" "common_name=${cert.commonName}" "alt_names=${lib.concatStringsSep "," cert.altNames}" -}}
            {{ .Data.private_key }}
            {{ .Data.certificate }}
            {{ .Data.issuing_ca }}
            {{- end -}}
          '';
          perms = "0640";
          command = lib.optionalString (cert.renewCommand != null) cert.renewCommand;
        }) cfg.certs;
      };
    };

    environment.systemPackages = let
      bootstrapScript = pkgs.writeShellApplication {
        name = "bootstrap-vault-agent";
        runtimeInputs = with pkgs; [ vault jq ];
        text = builtins.replaceStrings ["@vaultAddr@" "@approleName@"] [cfg.serverUrl cfg.roleName]
          (builtins.readFile ./scripts/bootstrap-vault-agent.sh);
      };
    in [ pkgs.vault pkgs.jq bootstrapScript ];

    environment.sessionVariables.VAULT_ADDR = cfg.serverUrl;
  };
}
