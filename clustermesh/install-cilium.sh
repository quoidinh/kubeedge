#!/usr/bin/env bash

set -e
set -o pipefail

cilium install \
    --set cluster.name=kind-cluster1 --set cluster.id=1 \
    --namespace kube-system \
    --values cilium-1-values.yaml \
    --set tls.ca.cert=$(base64 -i ./certs/ca.crt | tr -d \\n) \
    --set tls.ca.key=$(base64 -i ./certs/ca.key | tr -d \\n) \
    --set clustermesh.apiserver.tls.ca.cert=$(base64 -i ./certs/ca.crt | tr -d \\n) \
    --set clustermesh.apiserver.tls.ca.key=$(base64 -i ./certs/ca.key | tr -d \\n) \
    --set clustermesh.apiserver.tls.server.cert=$(base64 -i ./certs/clustermesh-server.crt | tr -d \\n) \
    --set clustermesh.apiserver.tls.server.key=$(base64 -i ./certs/clustermesh-server.key | tr -d \\n) \
    --set clustermesh.apiserver.tls.admin.cert=$(base64 -i ./certs/clustermesh-admin.crt | tr -d \\n) \
    --set clustermesh.apiserver.tls.admin.key=$(base64 -i ./certs/clustermesh-admin.key | tr -d \\n) \
    --set clustermesh.apiserver.tls.client.cert=$(base64 -i ./certs/clustermesh-client.crt | tr -d \\n) \
    --set clustermesh.apiserver.tls.client.key=$(base64 -i ./certs/clustermesh-client.key | tr -d \\n) \
    --set clustermesh.apiserver.tls.remote.cert=$(base64 -i ./certs/clustermesh-client.crt | tr -d \\n) \
    --set clustermesh.apiserver.tls.remote.key=$(base64 -i ./certs/clustermesh-client.key | tr -d \\n)
cilium clustermesh enable --service-type NodePort
cilium hubble enable --ui
 cilium clustermesh status --wait
cilium install \
    --set cluster.name=kind-cluster5 --set cluster.id=5 \
    --namespace kube-system \
    --values cilium-5-values.yaml \
    --set tls.ca.cert=$(base64 -i ./certs/ca.crt | tr -d \\n) \
    --set tls.ca.key=$(base64 -i ./certs/ca.key | tr -d \\n) \
    --set clustermesh.apiserver.tls.ca.cert=$(base64 -i ./certs/ca.crt | tr -d \\n) \
    --set clustermesh.apiserver.tls.ca.key=$(base64 -i ./certs/ca.key | tr -d \\n) \
    --set clustermesh.apiserver.tls.server.cert=$(base64 -i ./certs/clustermesh-server.crt | tr -d \\n) \
    --set clustermesh.apiserver.tls.server.key=$(base64 -i ./certs/clustermesh-server.key | tr -d \\n) \
    --set clustermesh.apiserver.tls.admin.cert=$(base64 -i ./certs/clustermesh-admin.crt | tr -d \\n) \
    --set clustermesh.apiserver.tls.admin.key=$(base64 -i ./certs/clustermesh-admin.key | tr -d \\n) \
    --set clustermesh.apiserver.tls.client.cert=$(base64 -i ./certs/clustermesh-client.crt | tr -d \\n) \
    --set clustermesh.apiserver.tls.client.key=$(base64 -i ./certs/clustermesh-client.key | tr -d \\n) \
    --set clustermesh.apiserver.tls.remote.cert=$(base64 -i ./certs/clustermesh-client.crt | tr -d \\n) \
    --set clustermesh.apiserver.tls.remote.key=$(base64 -i ./certs/clustermesh-client.key | tr -d \\n)
cilium clustermesh enable --service-type NodePort
cilium hubble enable --ui
 cilium clustermesh status --wait


# helm upgrade -i cilium cilium/cilium \
#     --version 1.15.4 \
#     --namespace kube-system \
#     --kube-context kind-cluster1 \
#     --values cilium-2-values.yaml \
#     --set tls.ca.cert=$(base64 -i ./certs/ca.crt | tr -d \\n) \
#     --set tls.ca.key=$(base64 -i ./certs/ca.key | tr -d \\n) \
#     --set clustermesh.apiserver.tls.ca.cert=$(base64 -i ./certs/ca.crt | tr -d \\n) \
#     --set clustermesh.apiserver.tls.ca.key=$(base64 -i ./certs/ca.key | tr -d \\n) \
#     --set clustermesh.apiserver.tls.server.cert=$(base64 -i ./certs/clustermesh-server.crt | tr -d \\n) \
#     --set clustermesh.apiserver.tls.server.key=$(base64 -i ./certs/clustermesh-server.key | tr -d \\n) \
#     --set clustermesh.apiserver.tls.admin.cert=$(base64 -i ./certs/clustermesh-admin.crt | tr -d \\n) \
#     --set clustermesh.apiserver.tls.admin.key=$(base64 -i ./certs/clustermesh-admin.key | tr -d \\n) \
#     --set clustermesh.apiserver.tls.client.cert=$(base64 -i ./certs/clustermesh-client.crt | tr -d \\n) \
#     --set clustermesh.apiserver.tls.client.key=$(base64 -i ./certs/clustermesh-client.key | tr -d \\n) \
#     --set clustermesh.apiserver.tls.remote.cert=$(base64 -i ./certs/clustermesh-client.crt | tr -d \\n) \
#     --set clustermesh.apiserver.tls.remote.key=$(base64 -i ./certs/clustermesh-client.key | tr -d \\n)
