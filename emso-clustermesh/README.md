# eks-cilium

## Install Cilium in EKS
### Prerequisites:
1. Cilium Version:1.10
2. EKS version:1.18 +
3. Nodes in all clusters must have IP connectivity between each other
### Step 1: helm add cilium repo
```
helm repo add cilium https://helm.cilium.io/
```
### Step 2: Generate Your Own Certificate
```
sh gen.sh
```
#### Copy dist/config.yaml content to replace cluster1.yaml and cluster2.yaml
```
      ca:
        cert:
        key:
      server:
        cert:
        key:
      remote:
        cert:
        key:
      admin:
        cert:
        key:

```
### Step 3: Replace k8sServiceHost value,it`s your eks master dns
```
k8sServiceHost: k8s-cluster-1.emso.vn
```
kind create cluster --config kind-1.yaml
kind create cluster --config kind-2.yaml

cilium install cilium cilium/cilium \
    --set cluster.name=k8s-cluster-1 --set cluster.id=1 \
    --namespace kube-system \
    --values cilium-1-values.yaml

cilium install cilium cilium/cilium \
    --set cluster.name=k8s-cluster-2 --set cluster.id=2 \
    --namespace kube-system \
    --values cilium-2-values.yaml

kubectl config use kind-k8s-cluster-1
cilium clustermesh enable --service-type NodePort
cilium hubble enable --ui
cilium clustermesh status --wait

kubectl config use kind-k8s-cluster-2
cilium clustermesh enable --service-type NodePort
cilium hubble enable --ui
cilium clustermesh status --wait

### Step 4: Install Cilium in all clusters
EKS Cluster 
```
kubectl patch daemonset aws-node -n kube-system -p '{"spec":{"template":{"spec":{"nodeSelector":{"no-such-node": "true"}}}}}'

kubectl patch daemonset kube-proxy -n kube-system -p '{"spec":{"template":{"spec":{"nodeSelector":{"no-such-node": "true"}}}}}'

helm install cilium --namespace=cilium cilium/cilium -f cluster{{clusterNumber}}.yaml
```

### Step 5: extract cluster mesh secret and import to other clusters
EkS Cluster 1
```
./k8s-extract-clustermesh-service-secret.sh > cluster1-secret.json

```
Switch to EKS Cluster 2
```
./k8s-import-clustermesh-secrets.sh cluster1-secret.json
```
EkS Cluster 2
```
./k8s-extract-clustermesh-service-secret.sh > cluster2-secret.json

```
Switch to EKS Cluster 1
```
./k8s-import-clustermesh-secrets.sh cluster2-secret.json
```
### Step 6: Restart Ciliium Daemonset in all clusters
```
kubectl rollout restart ds cilium -n cilium
```