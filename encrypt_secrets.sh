#!/bin/bash

# Check if Dart is installed
if ! command -v dart &> /dev/null; then
    echo "Dart is not installed. Please install Dart and try again."
    exit 1
fi

if [ "$#" -lt 1 ]; then
    echo "Usage: ./run_random_string.sh <entropy_string>"
    exit 1
fi

echo "Running Encrypt script with the entropy"

# Check if .env file exists
if [ ! -f .env.secret ]; then
    echo ".env.secret file not found."
    exit 1
fi

# Initialize an empty JSON object
json_object="{"

# Read each line from the .env.secret file
while IFS= read -r line; do
    # Extract key and value from the line
    key=$(echo "$line" | cut -d '=' -f 1)
    value=$(echo "$line" | cut -d '=' -f 2-)

    # Add key-value pair to the JSON object
    json_object+="\"$key\":\"$value\", "

done < .env.secret

# Remove the trailing comma and space from the JSON object
json_object="${json_object%, *} }"

#
> .env.secret



# Delete the secrets from the .env file
# Check if .env file exists
if [ -f .env ]; then
    # Define the keys to be removed
    keys_to_remove=(
      "FERAL_FILE_SECRET_KEY_TESTNET"
      "FERAL_FILE_SECRET_KEY_MAINNET"
      "CHAT_SERVER_HMAC_KEY"
      "AU_CLAIM_SECRET_KEY"
      "MIXPANEL_KEY"
      "METRIC_SECRET_KEY"
      "BRANCH_KEY"
      "SENTRY_DSN"
      "ONESIGNAL_APP_ID"
      "METRIC_ENDPOINT"
      "WEB3_RPC_MAINNET_URL"
      )
    # Iterate through the keys to be removed
    for key in "${keys_to_remove[@]}"; do
        # Check if the key exists in the .env file
        if grep -q "^$key=" .env; then
            sed -i '' "s/^$key=.*/$key=/" .env
        else
            echo "Key '$key' not found in .env file."
        fi
    done
    echo "Remove secrets in .env file successfully."
fi


# Run the Dart script with the provided argument and capture its output
encrypted_text=$(dart lib/encrypt_env/encrypt.dart "$json_object" "$1")

# Extract elements from the array
IFS=' ' read -r text nonceLength macLength <<< "$encrypted_text"

# Create the secrets.g.dart file
cat <<EOF > lib/encrypt_env/secrets.g.dart
import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

///=============================================================================
const _encryptedMessage = '$text';
const _nonceLength = $nonceLength;
const _macLength = $macLength;
///=============================================================================

String _generateKeyFromEntropy(int length) {
  ///===========================================================================
  var entropy = '$1';
  ///===========================================================================
  final random = Random(entropy.hashCode); // Use entropy's hash code as seed
  final entropyLength = entropy.length;
  final result = String.fromCharCodes(Iterable.generate(
      length, (_) => entropy.codeUnitAt(random.nextInt(entropyLength))));
  entropy = ''; // Clear the entropy
  return result;
}

Future<String> getSecretEnv() async {
  final algorithm = Chacha20.poly1305Aead();
  final key = _generateKeyFromEntropy(32);
  final bytes = utf8.encode(key);
  final secretKey = await algorithm.newSecretKeyFromBytes(bytes);
  final decryptText = await algorithm.decryptString(
    SecretBox.fromConcatenation(base64Decode(_encryptedMessage),
        nonceLength: _nonceLength, macLength: _macLength),
    secretKey: secretKey,
  );
  return decryptText;
}
EOF

echo "lib/encrypt_env/secrets.g.dart created successfully."