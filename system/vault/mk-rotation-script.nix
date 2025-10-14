# modules/vault/mk-rotation-script.nix
# Defines a function to generate the executable Vault Secret ID rotation script.

{ lib, pkgs,
  # --- Function Arguments ---
  roleIdPath,
  secretIdPath,
  secretIdAccessorPath,
  hostAppRoleName
}:

pkgs.writeScript "rotate-secret-id" ''
  #!${pkgs.bash}/bin/bash
  set -euo pipefail
  
  # Inject all needed paths and names as shell variables first
  ROLE_ID_PATH="${roleIdPath}" 
  SECRET_ID_PATH="${secretIdPath}" 
  SECRET_ID_ACCESSOR_PATH="${secretIdAccessorPath}"
  HOST_APPROLE="${hostAppRoleName}" # Inject AppRole name
  
  # 1. Check if files exist before proceeding. 
  if [[ ! -f "$ROLE_ID_PATH" ]] || [[ ! -f "$SECRET_ID_PATH" ]]; then
      echo "ERROR: AppRole credentials not found. Run the vault-bootstrap script first." >&2
      exit 1
  fi
  
  # Read the CURRENT Accessor ID for revocation later
  CURRENT_ACCESSOR_ID=$(cat "$SECRET_ID_ACCESSOR_PATH" 2>/dev/null || echo "")
  
  # 2. Authenticate to Vault to get a temporary token
  echo "Logging in with existing Secret ID to obtain a temporary token..."
  
  LOGIN_RESPONSE=$(${pkgs.vault}/bin/vault write -format=json auth/approle/login \
    role_id=@$ROLE_ID_PATH \
    secret_id=@$SECRET_ID_PATH)
  
  TEMP_TOKEN=$(echo "$LOGIN_RESPONSE" | ${pkgs.jq}/bin/jq -r '.auth.client_token')

  # 3. Generate the NEW Secret ID using the temporary token
  echo "Generating new Secret ID..."
  NEW_SECRET_ID_INFO=$(${pkgs.vault}/bin/vault write -format=json -f auth/approle/role/$HOST_APPROLE/secret-id \
    --header "X-Vault-Token: $TEMP_TOKEN")
    
  NEW_SECRET_ID=$(echo "$NEW_SECRET_ID_INFO" | ${pkgs.jq}/bin/jq -r '.data.secret_id')
  NEW_ACCESSOR_ID=$(echo "$NEW_SECRET_ID_INFO" | ${pkgs.jq}/bin/jq -r '.data.secret_id_accessor')
  
  # 4. Revoke the OLD Secret ID (CRITICAL)
  if [[ -n "$CURRENT_ACCESSOR_ID" ]]; then
      echo "Revoking old Secret ID: $CURRENT_ACCESSOR_ID"
      ${pkgs.vault}/bin/vault write -f auth/approle/role/$HOST_APPROLE/secret-id/destroy \
          secret_id_accessor="$CURRENT_ACCESSOR_ID" \
          --header "X-Vault-Token: $TEMP_TOKEN"
  fi
  
  # 5. Write NEW credentials to disk
  echo "Writing NEW Secret ID and Accessor to disk..."
  echo "$NEW_SECRET_ID" > "$SECRET_ID_PATH"
  echo "$NEW_ACCESSOR_ID" > "$SECRET_ID_ACCESSOR_PATH"
  
  # Set permissions and ownership
  ${pkgs.coreutils}/bin/chown vault-agent:vault-agent "$SECRET_ID_PATH" "$SECRET_ID_ACCESSOR_PATH"
  ${pkgs.coreutils}/bin/chmod 400 "$SECRET_ID_PATH" "$SECRET_ID_ACCESSOR_PATH"
  
  # 6. Revoke the temporary token used for this job
  ${pkgs.vault}/bin/vault token revoke "$TEMP_TOKEN" || true
  
  # 7. Restart the agent to pick up the new Secret ID and Token
  echo "Restarting vault-agent to use new credentials..."
  ${pkgs.systemd}/bin/systemctl restart vault-agent.service
  
  echo "Secret ID rotated and old ID revoked successfully."
''
