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

echo "Running Dart script with the provided argument: $1"

# Check if .env file exists
if [ ! -f .env ]; then
    echo ".env file not found."
    exit 1
fi

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

# Create an empty JSON object
json_object="{"

# Iterate through the keys to be removed
for key in "${keys_to_remove[@]}"; do
    # Check if the key exists in the .env file
    if grep -q "^$key=" .env; then
        # Extract value of the key
        value=$(grep "^$key=" .env | cut -d '=' -f 2-)

        # Add key-value pair to the JSON object
        json_object+="\"$key\":\"$value\", "
        sed -i '' "s/^$key=.*/$key=/" .env
    else
        echo "Key '$key' not found in .env file."
    fi
done

# Remove the trailing comma and space from the JSON object
json_object="${json_object%, *} }"


# Run the Dart script with the provided argument and capture its output
encrypted_text=$(dart encrypt.dart "$json_object" "$1")

# Extract elements from the array
IFS=' ' read -r text nonceLength macLength <<< "$encrypted_text"

# Create the secrets.g.dart file
cat <<EOF > lib/secrets.g.dart
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

echo "secrets.g.dart created successfully."