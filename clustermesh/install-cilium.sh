#!/usr/bin/env bash

set -e
set -o pipefail
for i in {1..5}; 
    do 
    echo $i; 
    cilium install \
    --set cluster.name=kind-cluster $i --set cluster.id= $i \
    --namespace kube-system \
    --values cilium- $i-values.yaml \
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
    # cilium clustermesh enable --service-type NodePort
    # cilium clustermesh enable --create-ca --context kind-cluster$i --service-type LoadBalancer
    cilium hubble enable --ui
    cilium clustermesh status --wait
    done
cilium install \
    --set cluster.name=kind-cluster2 --set cluster.id=2 \
    --namespace kube-system \
    --values cilium-2-values.yaml \
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
# cilium clustermesh enable --service-type NodePort
# cilium clustermesh enable --context kind-cluster1 --service-type LoadBalancer
cilium clustermesh enable --service-type LoadBalancer
# cilium hubble enable --ui
# kubectl get secret -n kube-system cilium-ca -o yaml > cilium-ca.yaml
# kubectl apply -f cilium-ca.yaml --context kind-cluster2


#  cilium clustermesh status --wait
cilium install \
    --set cluster.name=kind-cluster2 --set cluster.id=2 \
    --namespace kube-system \
    --values cilium-2-values.yaml \
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
# cilium clustermesh enable --service-type NodePort
# cilium hubble enable --ui
# cilium clustermesh status --wait
# cilium status --wait
helm --debug upgrade --install cilium cilium/cilium  --namespace kube-system --kube-context kind-cluster1  --values cilium-1-values.yaml
helm upgrade -i cilium cilium/cilium \
    --namespace kube-system \
    --kube-context kind-cluster1 \
    --values cilium-1-values.yaml \
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


sudo -i
echo | openssl s_client -showcerts -servername kind-cluster1.mesh.cilium.io -connect mesh.cilium.io:443 2>/dev/null | awk '/-----BEGIN CERTIFICATE-----/, /-----END CERTIFICATE-----/' >> /usr/local/share/ca-certificates/ca-certificates.crt 
update-ca-certificates