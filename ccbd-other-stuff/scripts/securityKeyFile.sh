#!/bin/bash
passPhrase=$1
filePath=$2

keyLegth=15360

openssl genrsa -aes256 -passout pass:${passPhrase} -out ${filePath}/private_key.pem ${keyLegth}

openssl rsa -in ${filePath}/private_key.pem -passin pass:${passPhrase} -outform PEM -pubout -out ${filePath}/public.pem
