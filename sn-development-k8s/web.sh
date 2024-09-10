kubectl apply -f deployment.yaml 
kubectl apply -f deployment-streaming.yaml 
kubectl apply -f deployment-media.yaml 
kubectl apply -f deployment-worker-default.yaml 
kubectl apply -f deployment-worker-pull.yaml 
kubectl apply -f deployment-worker-suggestion.yaml 
kubectl apply -f deployment-worker-classification.yaml 
kubectl apply -f deployment-worker-notification.yaml
kubectl apply -f deployment-worker-sync.yaml 

kubectl apply -f deployment-marketplace.yaml 
kubectl apply -f deployment-worker-marketplace.yaml 

kubectl apply -f deployment-fe.yaml 