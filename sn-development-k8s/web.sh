
kubectl delete -f deployment.yaml 
kubectl delete -f deployment-streaming.yaml 
kubectl delete -f deployment-media.yaml 
kubectl delete -f deployment-worker-default.yaml 
kubectl delete -f deployment-worker-pull.yaml 
kubectl delete -f deployment-worker-suggestion.yaml 
kubectl delete -f deployment-worker-classification.yaml 
kubectl delete -f deployment-worker-notification.yaml
kubectl delete -f deployment-worker-sync.yaml 

kubectl delete -f deployment-marketplace.yaml 
kubectl delete -f deployment-worker-marketplace.yaml 

kubectl delete -f deployment-fe.yaml 


kubectl apply -f marketplace-config.yaml
kubectl apply -f sn-config.yaml

# kubectl apply -f media-service.yaml 
# kubectl apply -f streaming-service.yaml 
# kubectl apply -f deployment-media.yaml 
# kubectl apply -f deployment-streaming.yaml 
# kubectl apply -f deployment-worker-pull.yaml 
# kubectl apply -f deployment-worker-suggestion.yaml 
# kubectl apply -f deployment-worker-classification.yaml 
# kubectl apply -f deployment-worker-sync.yaml 

kubectl apply -f deployment.yaml 
kubectl apply -f deployment-worker-default.yaml 
kubectl apply -f deployment-worker-notification.yaml
kubectl apply -f deployment-marketplace.yaml 
kubectl apply -f deployment-worker-marketplace.yaml 
kubectl apply -f deployment-fe.yaml 

kubectl apply -f marketplace-service.yaml 
kubectl apply -f web-service.yaml

# nohup kubectl -n default port-forward svc/sn-web --address 0.0.0.0  80:80&
# nohup kubectl -n default port-forward svc/sn-marketplace --address 0.0.0.0  80:80&
