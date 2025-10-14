# modules/vault/mk-bootstrap-script.nix
# Defines a function to generate the executable Vault bootstrap script.

{ lib, pkgs,
  # --- Function Arguments ---
  address,
  hostName,
  roleIdPath,
  secretIdPath,
  secretIdAccessorPath,
  allCertConfigs, # This is the config.custom.vault.certs attribute set
  generatePolicyHCL
}:
{ hostAppRoleName, ... }:
pkgs.writeScript "vault-bootstrap-${hostName}" ''
  #!${pkgs.bash}/bin/bash
  set -euo pipefail
  
  # Inject all required variables from the Nix context
  VAULT_ADDR=${address}
  HOST_APPROLE="${hostAppRoleName}"
  
  ROLE_ID_PATH="${roleIdPath}"
  SECRET_ID_PATH="${secretIdPath}"
  SECRET_ID_ACCESSOR_PATH="${secretIdAccessorPath}"

  if [[ -z "$VAULT_TOKEN" ]]; then
    echo "Error: VAULT_TOKEN environment variable must be set (e.g., your admin token)." >&2
    exit 1
  fi
  
  # Check for admin token and enable AppRole if necessary
  if ! ${pkgs.vault}/bin/vault auth list -detailed | ${pkgs.gnugrep}/bin/grep -q "approle/"; then
      echo "Enabling AppRole authentication method..."
      ${pkgs.vault}/bin/vault auth enable approle
  fi

  # --- Configure PKI and AppRole on Vault Server ---
  ${lib.strings.concatStringsSep "\n" (lib.attrValues (lib.mapAttrs (name: certCfg: 
    let
      roleName = certCfg.pkiRoleName;
      policyName = "${roleName}-policy";
      cn = lib.head certCfg.hostnames;
      allowedDomainsStr = lib.strings.concatStringsSep "," certCfg.hostnames;
    in
    ''
      echo "--- Configuring ${roleName} ---"
      
      # Policy write (using the policy HCL function passed in)
      echo -e "${generatePolicyHCL roleName}" | ${pkgs.vault}/bin/vault policy write ${policyName} -

      # PKI Role write: Defines what certs this role can issue
      ${pkgs.vault}/bin/vault write pki/roles/${roleName} \
          allowed_domains="${allowedDomainsStr}" \
          allow_subdomains=false \
          max_ttl="720h" \
          require_cn=true \
          key_usages="digital_signature,key_encipherment" \
          ext_key_usages="server_auth" \
          ttl="720h"

      echo "Writing AppRole: $HOST_APPROLE with policy ${policyName}"
      # Create/Update the host AppRole with the certificate policy attached
      ${pkgs.vault}/bin/vault write auth/approle/role/$HOST_APPROLE \
          token_policies="${policyName}" \
          bind_secret_id="true" \
          token_ttl="1h" \
          token_max_ttl="4h" \
          secret_id_num_uses=0     
          secret_id_ttl="720h"     # 30 days
    ''
  ) allCertConfigs))}

  # --- Provision Initial Credentials to Client ---
  
  echo "Fetching Role ID for $HOST_APPROLE..."
  ROLE_ID=$(${pkgs.vault}/bin/vault read -field=role_id auth/approle/role/$HOST_APPROLE/role-id)
  
  echo "Generating FIRST Secret ID (valid for 30 days)..."
  SECRET_ID_INFO_FILE=$(mktemp)
  ${pkgs.vault}/bin/vault write -f -format=json auth/approle/role/$HOST_APPROLE/secret-id > "$SECRET_ID_INFO_FILE"
  SECRET_ID=$(${pkgs.jq}/bin/jq -r '.data.secret_id' "$SECRET_ID_INFO_FILE")
  SECRET_ID_ACCESSOR=$(${pkgs.jq}/bin/jq -r '.data.secret_id_accessor' "$SECRET_ID_INFO_FILE")
  rm "$SECRET_ID_INFO_FILE"

  # Write Credentials
  echo "Writing Role ID, Secret ID, and Accessor to client paths..."
  echo "$ROLE_ID" > $ROLE_ID_PATH
  echo "$SECRET_ID" > $SECRET_ID_PATH
  echo "$SECRET_ID_ACCESSOR" > $SECRET_ID_ACCESSOR_PATH
  
  # Set permissions
  ${pkgs.coreutils}/bin/chown vault-agent:vault-agent $ROLE_ID_PATH $SECRET_ID_PATH $SECRET_ID_ACCESSOR_PATH
  ${pkgs.coreutils}/bin/chmod 400 $ROLE_ID_PATH $SECRET_ID_PATH $SECRET_ID_ACCESSOR_PATH

  echo "Restarting vault-agent and starting rotation timer..."
  ${pkgs.systemd}/bin/systemctl restart vault-agent.service
  ${pkgs.systemd}/bin/systemctl start vault-secret-id-rotate.timer

  echo "--- Vault Client Bootstrap Complete ---"
''
