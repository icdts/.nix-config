#!/usr/bin/env bash
set -euo pipefail

VAULT_ADDR="@vaultAddr@"
APPROLE_NAME="@approleName@"

# This script will create a unique identity (AppRole) for this machine in Vault.
#	You will need a Vault token with permissions to create AppRoles.
read -sp "Please enter your Vault Token: " VAULT_TOKEN
export VAULT_TOKEN

POLICY_NAME="${APPROLE_NAME}-policy"
vault policy write "${POLICY_NAME}" - <<EOF
# Manage its own AppRole SecretIDs
path "auth/approle/role/${APPROLE_NAME}/secret-id" {
  capabilities = ["update", "read"]
}
path "auth/approle/role/${APPROLE_NAME}/secret-id-accessor" {
  capabilities = ["update", "read"]
}
# Issue certificates
path "pki/issue/default-role" {
  capabilities = ["update"]
}
EOF
echo "✓ Vault policy '${POLICY_NAME}' created."

if ! vault read "auth/approle/role/${APPROLE_NAME}" > /dev/null 2>&1; then
  vault write "auth/approle/role/${APPROLE_NAME}" \
    token_policies="${POLICY_NAME}" \
    secret_id_ttl="30d" \
    secret_id_num_uses=0 # 0 means infinite uses, rotation is handled by TTL
  echo "✓ AppRole '${APPROLE_NAME}' created."
else
  # If role exists, just ensure the policy is attached
  vault write "auth/approle/role/${APPROLE_NAME}" token_policies="${POLICY_NAME}" > /dev/null
  echo "✓ AppRole '${APPROLE_NAME}' already exists, policy updated."
fi

ROLE_ID=$(vault read "auth/approle/role/${APPROLE_NAME}/role-id" -format=json | jq -r .data.role_id)
echo "✓ Fetched RoleID."

SECRET_ID=$(vault write -f "auth/approle/role/${APPROLE_NAME}/secret-id" -format=json | jq -r .data.secret_id)
echo "✓ Fetched initial SecretID."

SECRETS_DIR="/var/lib/vault-agent/secrets"
mkdir -p "${SECRETS_DIR}"
echo -n "${ROLE_ID}" > "${SECRETS_DIR}/role-id"
echo -n "${SECRET_ID}" > "${SECRETS_DIR}/secret-id"
chmod 600 "${SECRETS_DIR}"/*
echo "✓ RoleID and SecretID written to ${SECRETS_DIR}"

