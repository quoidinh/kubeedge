minikube start --nodes 2 --network-plugin=cni --cni=false -p cluster-cilium
kubectl -n kube-system get cm kubeadm-config -o yaml
kubectl -n default port-forward service/sample-api-web --address 0.0.0.0 7070:7070

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

helm repo add kedacore https://kedacore.github.io/charts
helm repo update
helm install keda kedacore/keda
kubectl apply -f https://github.com/kedacore/keda/releases/latest/download/keda-full.yaml

https://doc.kaas.thalesdigital.io/docs/Features/keda
https://www.private-ai.com/en/2022/05/31/how-to-autoscale-kubernetes-pods-based-on-gpu/


k3sup install --user root --ssh-key /Users/macbookpro16/sources/quoi_wow_ai --skip-install --ip 42.96.40.193  

https://github.com/zalando-incubator/kube-metrics-adapter
https://www.sandeepseeram.com/post/ci-cd-pipeline-with-gogs-drone-and-kubernetes