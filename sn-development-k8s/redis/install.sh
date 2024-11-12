helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install my-release bitnami/redis
export REDIS_PASSWORD=$(kubectl get secret --namespace default redis-test -o jsonpath="{.data.redis-password}" | base64 --decode)
kubectl apply -f pv.yaml
mkdir /storage
chown 10001:10001 /storage/
kubectl get pv
helm upgrade redis-1669709819 bitnami/redis --set auth.enabled=true
kubectl apply -f redis-commander.yaml

# https://www.techtarget.com/searchitoperations/tutorial/Deploy-a-Redis-Cluster-on-Kubernetes