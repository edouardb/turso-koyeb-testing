#!/bin/bash
set -e

if [[ -z $TURSO_TOKEN ]]; then
    echo "TURSO_TOKEN environment variable missing or empty. Please set it with a valid Turso token."
    exit 1
fi

if [[ -z $TURSO_DB_HOSTNAME ]]; then
    echo "TURSO_DB_HOSTNAME environment variable missing or empty. Please set it with a valid and existing Turso database hostname."
    exit 1
fi

mkdir -p certs
openssl genrsa -out ./certs/privkey.pem 2048
openssl rsa -in ./certs/privkey.pem -pubout -out ./certs/pubkey.pem

curl -H "Authorization: Bearer $TURSO_TOKEN" \
  -d '{"PublicKeyPem": "'"$(sed -z 's/\n/\\n/g' ./certs/pubkey.pem)"'"}' \
  https://api.chiseledge.com/v2/databases/$(echo $TURSO_DB_HOSTNAME | cut -d '-' -f 1)/certificates \
  | jq -r '.["CertificatePem"]' > ./certs/cert.pem

TURSO_DB_IPV6=$(dig AAAA +short $TURSO_DB_HOSTNAME)

./sqld --primary-grpc-url grpc://\[$TURSO_DB_IPV6\]:5001 \
  --primary-grpc-tls \
  --primary-grpc-ca-cert-file ./certs/cert.pem \
  --primary-grpc-cert-file ./certs/cert.pem \
  --primary-grpc-key-file ./certs/privkey.pem \
  --http-listen-addr 0.0.0.0:${PORT:-8000}