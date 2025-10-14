# Add custom.pki.certs option for generating web certificates for a host
{ config, pkgs, lib, ... }:
let
  mkSignedCert = { name, hostnames ? [ name ] }:
    pkgs.runCommand "cert-${name}" {
      caCert = config.sops.secrets."ca.crt".path;
      caKey = config.sops.secrets."ca.key".path;

      inherit hostnames;
      nativeBuildInputs = [ pkgs.openssl ];
      passAsFile = [ "caCert" "caKey" ];
    } ''
      openssl genpkey -algorithm RSA -out $out/key.pem
      openssl req -new -key $out/key.pem -out $out/csr.pem -subj "/CN=${name}"

      echo "[v3_req]" > $out/san.cnf
      echo "subjectAltName = @alt_names" >> $out/san.cnf
      echo "[alt_names]" >> $out/san.cnf

      i=1
      for domain in ${lib.escapeShellArgs hostnames}; do
        echo "DNS.$i = $domain" >> $out/san.cnf
        i=$((i+1))
      done

      openssl x509 -req -in $out/csr.pem \
        -CA $caCertPath -CAkey $caKeyPath -CAcreateserial \
        -out $out/cert.pem -days 365 -sha256 \
        -extfile $out/san.cnf -extensions v3_req
    '';

in
{
  options.custom.pki.certs = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule (
      { name, ... }: {
        options = {
          enable = lib.mkEnableOption "certificate for this host";
          hostnames = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = "Hostnames (Subject Alternative Names) for the certificate.";
            default = [];
          };
          certificatePath = lib.mkOption {
            type = lib.types.str;
            readOnly = true;
            internal = true;
            description = "The absolute path to the generated certificate file.";
            default = "/etc/ssl/${name}.crt";
          };
          keyPath = lib.mkOption {
            type = lib.types.str;
            readOnly = true;
            internal = true;
            description = "The absolute path to the generated key file.";
            default = "/etc/ssl/${name}.key";
          };
        };
      }
    ));
    default = {};
    description = "Declaratively generate server certificates signed by the shared CA.";
  };

  config.systemd.tmpfiles.rules = lib.mkIf (config.custom.pki.certs != {}) (
    lib.mapAttrsToList (name: certDef:
      let
        cert = mkSignedCert {
          name = name;
          hostnames = if certDef.hostnames == [] then [ name ] else certDef.hostnames;
        };
      in
      lib.mkIf certDef.enable ''
        L+ /etc/ssl/${name}.crt - - - - ${cert}/cert.pem
        L+ /etc/ssl/${name}.key - - - - ${cert}/key.pem
      ''
    ) config.custom.pki.certs
  );
}
