#!/bin/bash

# Ensure directories exist on both systems
echo "Creating directories on both systems..."
ssh kali@192.168.18.84 'mkdir -p /home/kali/folder2'
mkdir -p /home/susandhamala/folder1

# Generate asymmetric keys on System 1
echo "Generating RSA keys on System 1..."
openssl genpkey -algorithm RSA -out /home/susandhamala/folder1/private_key_susan.pem -pkeyopt rsa_keygen_bits:2048
openssl rsa -pubout -in /home/susandhamala/folder1/private_key_susan.pem -out /home/susandhamala/folder1/public_key_susan.pem

# Generate asymmetric keys on System 2
echo "Generating RSA keys on System 2..."
ssh kali@192.168.18.84 'openssl genpkey -algorithm RSA -out /home/kali/folder2/private_key_kali.pem -pkeyopt rsa_keygen_bits:2048'
ssh kali@192.168.18.84 'openssl rsa -pubout -in /home/kali/folder2/private_key_kali.pem -out /home/kali/folder2/public_key_kali.pem'

# Generate symmetric key and data on System 1
echo "Generating symmetric key and data on System 1..."
openssl rand -base64 32 > /home/susandhamala/folder1/symmetric_key
echo 'This is some data to encrypt' > /home/susandhamala/folder1/data.txt

# Copy public keys between systems
echo "Copying public keys between systems..."
scp /home/susandhamala/folder1/public_key_susan.pem kali@192.168.18.84:/home/kali/folder2/
scp kali@192.168.18.84:/home/kali/folder2/public_key_kali.pem /home/susandhamala/folder1/

# Create crontab entry on System 1
echo "Creating crontab entry on System 1..."
(crontab -l 2>/dev/null; echo '30 16 * * * /home/susandhamala/folder1/generate_and_sign.sh') | crontab -

# Generate and sign script on System 1
echo "Creating generate_and_sign.sh script on System 1..."
echo "Generated file at $(date)" > /home/susandhamala/folder1/generated_file.txt
openssl dgst -sha256 -sign /home/susandhamala/folder1/private_key_susan.pem -out /home/susandhamala/folder1/signature.bin /home/susandhamala/folder1/generated_file.txt
scp /home/susandhamala/folder1/generated_file.txt kali@192.168.18.84:/home/kali/folder2/
scp /home/susandhamala/folder1/signature.bin kali@192.168.18.84:/home/kali/folder2/
ssh kali@192.168.18.84 "openssl dgst -sha256 -verify /home/kali/folder2/public_key_susan.pem -signature /home/kali/folder2/signature.bin /home/kali/folder2/generated_file.txt && echo 'Verification successful'"

echo "Automation script completed successfully."
