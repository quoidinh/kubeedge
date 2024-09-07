#!/bin/bash

mkdir -p certs

# openssl genrsa -out certs/ca.key 4096
# openssl req -x509 -new  -sha512 -key  certs/ca.key -config ca.conf -days 365 -out certs/ca.crt
openssl req -x509 -new -sha512 -noenc \
-key certs/ca.key -days 365 \
-config ca.conf \
-out certs/ca.crt

certs=(
    "clustermesh-server" "clustermesh-admin" "clustermesh-client"
)

for i in ${certs[*]}; do
  openssl genrsa -out "certs/${i}.key" 4096

  openssl req -new -key "certs/${i}.key" -sha256 \
    -config "ca.conf" \
    -out "certs/${i}.csr"

  openssl x509 -req -days 3650 -in "certs/${i}.csr" \
    # -new \
    # -extensions v3_req
    -sha256 -CA "certs/ca.crt" \
    -CAkey "certs/ca.key" \
    -CAcreateserial \
    -out "certs/${i}.crt" \
    -copy_extensions copyall \
done
#  https://fossies.org/linux/cilium/clustermesh-apiserver/tls.rst
# https://gist.github.com/ganeshan/8ad68b18159bf7ab2abcfcbebcc1086c
# https://docs.cilium.io/en/stable/security/tls-visibility/

#  openssl genrsa -out "certs/clustermesh-server.key" 4096

#   openssl req -new -key "certs/clustermesh-server.key"  -config "ca.conf" -out "certs/clustermesh-server.csr"
  
#   openssl x509 -req -days 365 -in "certs/clustermesh-server.csr" \
#     -sha256 -CA "certs/ca.crt" \
#     -CAkey "certs/ca.key" \
#     -CAcreateserial \
#     -out "certs/clustermesh-server.crt"

#   openssl genrsa -out "certs/clustermesh-admin.key" 4096

#   openssl req -new -key "certs/clustermesh-admin.key" -sha256 \
#     -config "ca.conf"  \
#     -out "certs/clustermesh-admin.csr"
  
#   openssl x509 -req -days 365 -in "certs/clustermesh-admin.csr" \
#     -sha256 -CA "certs/ca.crt" \
#     -CAkey "certs/ca.key" \
#     -CAcreateserial \
#     -out "certs/clustermesh-admin.crt"

#   openssl genrsa -out "certs/clustermesh-client.key" 4096

#   openssl req -new -key "certs/clustermesh-client.key" -sha256 \
#     -config "ca.conf"\
#     -out "certs/clustermesh-client.csr"
  
#   openssl x509 -req -days 365 -in "certs/clustermesh-client.csr" \
#     -sha256 -CA "certs/ca.crt" \
#     -CAkey "certs/ca.key" \
#     -CAcreateserial \
#     -out "certs/clustermesh-client.crt"