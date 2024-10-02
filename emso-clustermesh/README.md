# cilium

## Install Cilium
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
### Step 3: Replace k8sServiceHost value,it`s your master dns
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

cilium clustermesh connect --context kind-k8s-cluster-1 --destination-context kind-k8s-cluster-2

### Step 4: Install metallb in all clusters

```
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml --context=kind-k8s-cluster-1
kubectl wait deployment -n metallb-system controller --for condition=Available=True --timeout=90s --context kind-k8s-cluster-1
kubectl apply -f metallb-1.yaml --context=kind-cluster1

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml --context=kind-k8s-cluster-2
kubectl wait deployment -n metallb-system controller --for condition=Available=True --timeout=90s --context kind-k8s-cluster-2
kubectl apply -f metallb-1.yaml --context=kind-k8s-cluster-2

### Step 4: Install Cilium in all clusters

```
helm install cilium --namespace=cilium cilium/cilium -f cilium-1-values.yaml
helm install cilium --namespace=cilium cilium/cilium -f cilium-2-values.yaml
```

### Step 5: extract cluster mesh secret and import to other clusters
 Cluster 1
```
./k8s-extract-clustermesh-service-secret.sh > cluster1-secret.json

```
Switch to Cluster 2
```
./k8s-import-clustermesh-secrets.sh cluster1-secret.json
```
 Cluster 2
```
./k8s-extract-clustermesh-service-secret.sh > cluster2-secret.json

```
Switch to  Cluster 1
```
./k8s-import-clustermesh-secrets.sh cluster2-secret.json
```
### Step 6: Restart Ciliium Daemonset in all clusters
```
kubectl rollout restart ds cilium -n cilium
```

