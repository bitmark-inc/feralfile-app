#!/bin/bash

# Function to encrypt a secret using GitHub Secrets
encrypt_secret() {
    local secret_name="$1"
    local encrypted_value
    encrypted_value=$(echo "${!secret_name}")

    # Replace plaintext secret with encrypted one in all relevant files
    find . -type f \( -name "*.sh" -o -name "*.yaml" -o -name "*.yml" \) -print0 | while IFS= read -r -d $'\0' file; do
        sed -i "s|${secret_name}|${encrypted_value}|g" "$file"
    done
}

# Replace plaintext secrets with encrypted ones
# Modify this section to include all your secrets stored in GitHub Secrets
encrypt_secret "INDEXER_MAINNET_API_URL"
encrypt_secret "INDEXER_TESTNET_API_URL"
encrypt_secret "WEB3_RPC_MAINNET_URL"
encrypt_secret "WEB3_MAINNET_CHAIN_ID"
encrypt_secret "WEB3_RPC_TESTNET_URL"
encrypt_secret "WEB3_TESTNET_CHAIN_ID"
encrypt_secret "TEZOS_NODE_CLIENT_MAINNET_URL"
encrypt_secret "TEZOS_NODE_CLIENT_TESTNET_URL"
encrypt_secret "BITMARK_API_MAINNET_URL"
encrypt_secret "BITMARK_API_TESTNET_URL"
encrypt_secret "FERAL_FILE_API_MAINNET_URL"
encrypt_secret "FERAL_FILE_API_TESTNET_URL"
encrypt_secret "FERAL_FILE_SECRET_KEY_TESTNET"
encrypt_secret "FERAL_FILE_SECRET_KEY_MAINNET"
encrypt_secret "FERAL_FILE_ASSET_URL_TESTNET"
encrypt_secret "FERAL_FILE_ASSET_URL_MAINNET"
encrypt_secret "EXTENSION_SUPPORT_MAINNET_URL"
encrypt_secret "EXTENSION_SUPPORT_TESTNET_URL"
encrypt_secret "CONNECT_WEBSOCKET_MAINNET_URL"
encrypt_secret "CONNECT_WEBSOCKET_TESTNET_URL"
encrypt_secret "AUTONOMY_AUTH_URL"
encrypt_secret "CUSTOMER_SUPPORT_URL"
encrypt_secret "RENDERING_REPORT_URL"
encrypt_secret "FEED_URL"
encrypt_secret "CURRENCY_EXCHANGE_URL"
encrypt_secret "AUTONOMY_PUBDOC_URL"
encrypt_secret "AUTONOMY_IPFS_PREFIX"
encrypt_secret "TOKEN_WEBVIEW_PREFIX"
encrypt_secret "FERAL_FILE_AUTHORIZATION_PREFIX"
encrypt_secret "SENTRY_DSN"
encrypt_secret "ONESIGNAL_APP_ID"
encrypt_secret "AWS_IDENTITY_POOL_ID"
encrypt_secret "AUTONOMY_SHARD_SERVICE"
encrypt_secret "METRIC_ENDPOINT"
encrypt_secret "METRIC_SECRET_KEY"
encrypt_secret "BRANCH_KEY"
encrypt_secret "MIXPANEL_KEY"
encrypt_secret "CLOUD_FLARE_IMAGE_URL_PREFIX"
encrypt_secret "AU_CLAIM_SECRET_KEY"
encrypt_secret "AU_CLAIM_API_URL"
encrypt_secret "POSTCARD_CONTRACT_ADDRESS"
encrypt_secret "CHAT_SERVER_HMAC_KEY"
encrypt_secret "CHAT_SERVER_URL"
encrypt_secret "TZKT_MAINNET_URL"
encrypt_secret "TZKT_TESTNET_URL"
encrypt_secret "AUTONOMY_AIRDROP_URL"
encrypt_secret "AUTONOMY_AIRDROP_CONTRACT_ADDRESS"
encrypt_secret "AUTONOMY_ACTIVATION_URL"
encrypt_secret "AUTONOMY_MERCHANDISE_API_URL"
encrypt_secret "AUTONOMY_MERCHANDISE_BASE_URL"
encrypt_secret "PAY_TO_MINT_BASE_URL"



# Add more secrets as needed

echo "Secrets encrypted successfully!"
