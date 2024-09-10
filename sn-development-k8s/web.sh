kubectl apply -f sn-deployment-k8s/web/deployment.yaml 
kubectl apply -f sn-deployment-k8s/web/deployment-streaming.yaml 
kubectl apply -f sn-deployment-k8s/web/deployment-media.yaml 
kubectl apply -f sn-deployment-k8s/web/deployment-worker-default.yaml 
kubectl apply -f sn-deployment-k8s/web/deployment-worker-pull.yaml 
kubectl apply -f sn-deployment-k8s/web/deployment-worker-suggestion.yaml 
kubectl apply -f sn-deployment-k8s/web/deployment-worker-classification.yaml 
kubectl apply -f sn-deployment-k8s/web/deployment-worker-notification.yaml
kubectl apply -f sn-deployment-k8s/web/deployment-worker-sync.yaml 

kubectl apply -f sn-deployment-k8s/web/deployment-marketplace.yaml 
kubectl apply -f sn-deployment-k8s/web/deployment-worker-marketplace.yaml 

kubectl apply -f sn-deployment-k8s/web/deployment-fe.yaml 