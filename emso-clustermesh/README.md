# cilium

## Install Cilium
### Prerequisites:
1. Cilium Version:1.10
2. Nodes in all clusters must have IP connectivity between each other
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
k8sServiceHost: k8s-cluster-1.local
```
kind create cluster --config kind-1.yaml
kind create cluster --config kind-2.yaml
kind create cluster --config kind-3.yaml

kubectl config use kind-k8s-cluster-1
cilium install cilium cilium/cilium  --version 1.16.2 \
    --set cluster.name=k8s-cluster-1 --set cluster.id=1 \
    --namespace kube-system \
    --values cilium-1-values.yaml
kubectl config use kind-k8s-cluster-2
cilium install cilium cilium/cilium --version 1.16.2 \
    --set cluster.name=k8s-cluster-2 --set cluster.id=2 \
    --namespace kube-system \
    --values cilium-2-values.yaml

kubectl config use kind-k8s-cluster-3
cilium install cilium cilium/cilium --version 1.16.2 \
    --set cluster.name=k8s-cluster-3 --set cluster.id=3 \
    --namespace kube-system \
    --values cilium-3-values.yaml
cilium clustermesh enable --service-type NodePort
cilium hubble enable --ui 
cilium clustermesh status --wait

kubectl config use kind-k8s-cluster-1
cilium clustermesh enable --service-type NodePort
cilium hubble enable --ui
cilium clustermesh status --wait

kubectl config use kind-k8s-cluster-2
cilium clustermesh enable --service-type NodePort
cilium hubble enable --ui
cilium clustermesh status --wait

cilium clustermesh connect --context kind-k8s-cluster-1 --destination-context kind-k8s-cluster-2
cilium clustermesh connect --context kind-k8s-cluster-3 --destination-context k8s-cluster-1

### Step 4: Install metallb in all clusters

```

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml --context=kind-k8s-cluster-1
kubectl wait deployment -n metallb-system controller --for condition=Available=True --timeout=90s --context kind-k8s-cluster-1
kubectl apply -f metallb-1.yaml --context=kind-k8s-cluster-1



kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml --context=kind-k8s-cluster-2
kubectl wait deployment -n metallb-system controller --for condition=Available=True --timeout=90s --context kind-k8s-cluster-2
kubectl apply -f metallb-1.yaml --context=kind-k8s-cluster-2

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

### Step 7: install metrics server
```
kubectl config use kind-k8s-cluster-1
kubectl delete -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[
{
"op": "add",
"path": "/spec/template/spec/hostNetwork",
"value": true
},
{
"op": "replace",
"path": "/spec/template/spec/containers/0/args",
"value": [
"--cert-dir=/tmp",
"--secure-port=4443",
"--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname",
"--kubelet-use-node-status-port",
"--metric-resolution=30s",
"--kubelet-insecure-tls"
]
},
{
"op": "replace",
"path": "/spec/template/spec/containers/0/ports/0/containerPort",
"value": 4443
}
]'

kubectl config use kind-k8s-cluster-2
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[
{
"op": "add",
"path": "/spec/template/spec/hostNetwork",
"value": true
},
{
"op": "replace",
"path": "/spec/template/spec/containers/0/args",
"value": [
"--cert-dir=/tmp",
"--secure-port=4443",
"--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname",
"--kubelet-use-node-status-port",
"--metric-resolution=15s",
"--kubelet-insecure-tls"
]
},
{
"op": "replace",
"path": "/spec/template/spec/containers/0/ports/0/containerPort",
"value": 4443
}
]'
```

### Step 8: install keda
```
helm repo add kedacore https://kedacore.github.io/charts
helm repo update
helm install keda kedacore/keda
or
kubectl apply -f https://github.com/kedacore/keda/releases/latest/download/keda-full.yaml
```
kubectl create secret docker-registry registry --docker-server=registry.emso.vn --docker-username=admin --docker-password=hoathang9695
docker login --username admin --password hoathang9695 registry.emso.vn
kubectl apply -f sn-development-k8s/web
```
or 
```
kubectl apply -f sn-development-k8s/pt
kubectl apply -f sn-development-k8s/chat
kubectl apply -f sn-development-k8s/notification
```

```
nohup kubectl -n default port-forward services/sn-fe --address 0.0.0.0 8888:80&

#emso-streaming.emso.vn
nohup kubectl -n default port-forward services/sn-streaming --address 0.0.0.0 8886:80&
#emso-media.emso.vn
nohup kubectl -n default port-forward services/sn-media --address 0.0.0.0 8885:80&
 #emso-marketplace.emso.vn
nohup kubectl -n default port-forward services/sn-marketplace --address 0.0.0.0 8884:80&
#emso-sn.emso.vn
nohup kubectl -n default port-forward services/sn-web --address 0.0.0.0 8883:80&



nohup kubectl -n default port-forward services/sn-pt --address 0.0.0.0 8887:80&
nohup kubectl -n default port-forward services/sn-chat --address 0.0.0.0 8886:80&
nohup kubectl -n default port-forward service/notification-web --address 0.0.0.0 8885:80&
nohup kubectl -n default port-forward service/notification-ws --address 0.0.0.0 8884:80&
nohup kubectl -n default port-forward service/notification-api --address 0.0.0.0 8883:80&

nohup kubectl -n kube-system port-forward service/clustermesh-apiserver --address 0.0.0.0 2379:2379&


nohup kubectl -n default port-forward service/redis-stack --address 0.0.0.0 6379:6379&
nohup kubectl -n devops-tools port-forward service/jenkins-service --address 0.0.0.0 8080:8080&
nohup kubectl --namespace default port-forward svc/myjenkins --address 0.0.0.0 8080:8080&
kubectl get pod,hpa,svc,deploy

kubectl apply -f monitor-grafana-promethus-yugabyte-v2.yaml

sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
apt update
apt install -y postgresql-client-14

/usr/lib/postgresql/14/bin/pg_restore  -h 172.16.0.157 -p 5433 -U yugabyte -d postgres test.sql
/usr/lib/postgresql/14/bin/pg_dump  -h 172.16.0.251 -p 6432 -U thangnv -d sn_production_backup > test.sql
sudo apt-get install -y postgresql-client
psql --username yugabyte --dbname postgres -h 172.16.0.157 -p 5433 -f test.sql
```
### Step 9: install Ansible for devops

```
sudo apt-add-repository ppa:ansible/ansible
sudo apt update
sudo apt install ansible
```

### Step 9: install lens for monitor

```
https://docs.k8slens.dev/getting-started/install-lens/#install-lens-desktop-on-windows
```

kubectl port-forward service/sn-web --namespace=default --address 0.0.0.0 8888:80
server {
        listen 80;
        server_name stagv1.emso.vn; #change to your domain name

        location / {
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header Host $http_host;
                proxy_pass http://172.16.0.66:8888/;  #change to your internal server IP
                proxy_redirect off;
        }
}
server {
        server_name stagv1.emso.vn;
        gzip on;
        client_max_body_size 2G;
        gzip_types * ;
        gzip_proxied no-cache no-store private expired auth;
        gzip_min_length 1k;
        gzip_buffers    4 16k;
        gzip_comp_level 9;
        gzip_disable "MSIE [1-6]\.";
        gzip_vary on;

        location / {
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header Host $http_host;
                proxy_pass http://172.16.0.66:8888;
                proxy_redirect off;
        }

}

sudo ln -s /etc/nginx/sites-available/stagv1.emso.vn /etc/nginx/sites-enabled/


kubectl rollout restart deployment.apps/sn-web
kubectl rollout restart deployment.apps/sn-media


helm repo add jenkins https://charts.jenkins.io
helm repo update
helm upgrade --install myjenkins jenkins/jenkins
 kubectl exec --namespace default -it svc/myjenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password && echo