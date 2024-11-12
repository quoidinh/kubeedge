helm repo add jenkins https://charts.jenkins.io
helm repo update
helm upgrade --install myjenkins jenkins/jenkins
 kubectl exec --namespace default -it svc/myjenkins -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password && echo