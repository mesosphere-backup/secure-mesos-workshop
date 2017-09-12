#!/bin/bash
set -e

mkdir -p ssl

# Generate a key file.
openssl genrsa -f4 -out ssl/key.pem 4096


# Generate a certificte.
openssl req -new -x509 -days 365 -key ssl/key.pem -out ssl/cert.pem -subj "/C=US"
