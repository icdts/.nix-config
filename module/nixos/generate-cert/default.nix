{ config, lib, pkgs, ... }:

let
  cfg = config.custom.cert-generation;
in
{
  options.custom.cert-generation = {
    enable = lib.mkEnableOption "the custom certificate generation script";

    caKeyFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to the CA private key PEM file.";
    };

    caCertFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to the CA public certificate PEM file.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (let
        template = builtins.readFile ./generate-cert.sh.in;

        scriptContent = builtins.replaceStrings
          [ "@shell@" "@openssl@" "@caKeyFile@" "@caCertFile@" ]
          [ pkgs.runtimeShell pkgs.openssl cfg.caKeyFile cfg.caCertFile ]
          template;

      in pkgs.writeShellScriptBin "generate-cert" scriptContent)
    ];
  };
}
