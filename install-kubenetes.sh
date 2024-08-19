#!/bin/bash
echo "Disabling swap...."
sudo swapoff -a
sudo ufw disable
service iptables stop
sudo apt list --upgradable
sudo apt-get upgrade
sudo sed -i.bak '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
echo "Installing necessary dependencies...."
sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y
echo "Setting up hostname...."
sudo hostnamectl set-hostname "k8s-master"
PUBLIC_IP_ADDRESS=`hostname -I|cut -d" " -f 1` #hostname -I|cut -d" " -f 1 #172.17.0.1
sudo echo "${PUBLIC_IP_ADDRESS}  k8s-master" >> /etc/hosts
echo "Removing existing Docker Installation...."
sudo apt install ipvsadm
sudo apt-get purge aufs-tools docker-ce docker-ce-cli containerd.io pigz cgroupfs-mount -y
sudo apt-get purge  kubeadm kubelet kubectl kubernetes-cni -y
snap stop kubelet
sudo rm -rf /etc/kubernetes
sudo rm -rf $HOME/.kube/config
sudo rm -rf /var/lib/etcd
sudo rm -rf /var/lib/docker
sudo rm -rf /opt/containerd
sudo rm -rf ~/.kube 
sudo ipvsadm --clear
sudo apt autoremove -y

apt-get update && \
 apt-get install -y apt-transport-https add-apt-repository "deb [arch=amd64] download.docker.com/linux/ubuntu bionic stable" curl -s packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - echo "deb apt.kubernetes.io kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list apt update && \
 apt install -qy docker.io apt-get update && \
 apt-get install -y kubeadm kubelet kubectl kubernetes-cni kubeadm init --ignore-preflight-errors=all –

echo "Installing Docker...."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
### Add Docker apt repository.
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

## Install Docker CE.
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io -y

# Setup daemon.

sudo mkdir -p /etc/systemd/system/docker.service.d

sudo cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "exec-opts": [
         "native.cgroupdriver=cgroupfs"
     ],
  "storage-driver": "overlay2",
 
     "node-generic-resources": [
    
     ],
     "features": {
         "buildkit" : true
     },  
     "debug": true
}
EOF
sudo cat >  /lib/systemd/system/docker.service <<EOF
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service containerd.service
Wants=network-online.target
Requires=docker.socket containerd.service

[Service]
Type=notify
# the default is not to use systemd for cgroups because the delegate issues still
# exists and systemd currently does not support the cgroup feature set required
# for containers run by docker

ExecStart=/usr/bin/dockerd --config-file=/etc/docker/daemon.json -H tcp://0.0.0.0:4243 -H fd:// --containerd=/run/containerd/containerd.sock




ExecReload=/bin/kill -s HUP $MAINPID
TimeoutSec=0
RestartSec=2
Restart=always

# Note that StartLimit* options were moved from "Service" to "Unit" in systemd 229.
# Both the old, and new location are accepted by systemd 229 and up, so using the old location
# to make them work for either version of systemd.
StartLimitBurst=3

# Note that StartLimitInterval was renamed to StartLimitIntervalSec in systemd 230.
# Both the old, and new name are accepted by systemd 230 and up, so using the old name to make
# this option work for either version of systemd.
StartLimitInterval=60s

# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity

# Comment TasksMax if your systemd version does not support it.
# Only systemd 226 and above support this option.
TasksMax=infinity

# set delegate yes so that systemd does not reset the cgroups of docker containers
Delegate=yes

# kill only the docker process, not all processes in the cgroup
KillMode=process
OOMScoreAdjust=-500

[Install]
WantedBy=multi-user.target
EOF
sudo cat > /etc/containerd/config.toml <<EOF
#   Copyright 2018-2022 Docker Inc.

#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at

#       http://www.apache.org/licenses/LICENSE-2.0

#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

disabled_plugins = []

#root = "/var/lib/containerd"
#state = "/run/containerd"
#subreaper = true
#oom_score = 0

#[grpc]
#  address = "/run/containerd/containerd.sock"
#  uid = 0
#  gid = 0

#[debug]
#  address = "/run/containerd/debug.sock"
#  uid = 0
#  gid = 0
#  level = "info"
EOF

# # Restart docker.
sudo usermod -aG docker $USER
sudo systemctl daemon-reload
sudo systemctl restart containerd
sudo systemctl restart docker

#install helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

#install kind
# For AMD64 / x86_64
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-amd64
# For ARM64
[ $(uname -m) = aarch64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.23.0/kind-linux-arm64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

echo "Setting up Kubernetes Package Repository..."
sudo apt-get install apt-transport-https curl -y 
echo "Installing Kubernetes..."

sudo mkdir /etc/apt/keyrings/
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
apt list --upgradable
apt update
apt upgrade

sudo apt install kubeadm kubelet kubectl
sudo kubeadm config images pull

sudo kubeadm reset
sudo rm $HOME/.kube/config
sudo rm -rf /etc/cni/net.d
swapoff -a    # will turn off the swap 

# iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X  # will reset iptables

# kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=sp-ns:sp-sa
# kubeadm init --upload-certs --pod-network-cidr=10.96.0.0/16 --skip-phases=addon/kube-proxy --v=6 --ignore-preflight-errors=all 
# sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --v=6 --ignore-preflight-errors=all
# kubeadm init --control-plane-endpoint="127.0.0.1:6443" --upload-certs --apiserver-advertise-address=127.0.0.1 --v=6 --ignore-preflight-errors=all --pod-network-cidr=10.0.0.0.0/16
# sudo kubeadm init --v=6 --ignore-preflight-errors=all
# kubeadm init --control-plane-endpoint="172.17.0.1:6443" --upload-certs --apiserver-advertise-address=172.17.0.1 --v=6 --ignore-preflight-errors=all
# sudo kubeadm init --control-plane-endpoint=172.17.0.1:6443 --skip-phases=addon/kube-proxy --upload-certs --apiserver-advertise-address=172.17.0.1 --pod-network-cidr 10.244.0.0/16  --v=6 --ignore-preflight-errors=all
sudo kubeadm init --pod-network-cidr=10.0.0.0/16 --v=6 --ignore-preflight-errors=all    
# sudo kubeadm init --v=6 --ignore-preflight-errors=all    

# sudo kubeadm init --upload-certs --apiserver-advertise-address=43.132.179.71 --v=6 --ignore-preflight-errors=all

# kubeadm join kube1.tonyshark.lol:6443 --token itm1v6.50adqfgmi6r399b8 \
# 	--discovery-token-ca-cert-hash sha256:a499acfbd899d882a92bc3fabd7ae56854661dfa3bbe2ada85b784c16bc4f8e3 --v=6 --ignore-preflight-errors=all
#https://stackoverflow.com/questions/53525975/kubernetes-error-uploading-crisocket-timed-out-waiting-for-the-condition
sudo sleep 10
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
export KUBECONFIG=$HOME/.kube/config

# echo "Installing Flannel..."
# sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
# sudo cat >  /run/flannel/subnet.env <<EOF
# FLANNEL_NETWORK=10.0.0.0/16
# FLANNEL_SUBNET=10.0.0.1/24
# FLANNEL_MTU=1450
# FLANNEL_IPMASQ=true
# EOF
apt update
apt install containerd.io
sudo rm /etc/containerd/config.toml

systemctl restart containerd
sudo systemctl restart containerd
sudo systemctl restart docker
sudo systemctl restart kubelet

echo "Kubernetes Installation finished..."
echo "Waiting 30 seconds for the cluster to go online..."
sudo sleep 5

echo "Testing Kubernetes namespaces... "
kubectl get pods --all-namespaces
echo "Testing Kubernetes nodes... "
kubectl get nodes
kubectl describe nodes

# sudo systemctl status kubelet
#install cilium
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz.sha256sum

# curl -LO https://raw.githubusercontent.com/cilium/cilium/1.16.1/Documentation/installation/kind-config.yaml
# kind create cluster --config=kind-config.yaml

helm repo add cilium https://helm.cilium.io/
# helm upgrade cilium cilium/cilium --version 1.16.1 \
#    --namespace kube-system \
#    --reuse-values \
#    --set hubble.relay.enabled=true \
#    --set hubble.ui.enabled=true

# helm install cilium cilium/cilium --version 1.16.1 --namespace kube-system
# helm install cilium cilium/cilium --version 1.15.1 --namespace kube-system \
#    --set hubble.relay.enabled=true \
#    --set hubble.enabled=true \
#    --set hubble.relay.enabled=true \
#    --set hubble.ui.enabled=true \
#    --set hubble.ui.service.type=NodePort \
#    --set hubble.relay.service.type=NodePort \
#    --set hubble.ui.enabled=true \
#    --set hubble.metrics.dashboards.enabled=true \
#    --set hostServices.enabled=false \
#    --set externalIPs.enabled=true \
#    --set nodePort.enabled=true \
  #  --set hubble.tls.enabled=false \
  #  --set hubble.tls.auto.enabled=false \
  #  --set hubble.relay.tls.server.enabled=false \
  # --set hubble.metrics.enabled="{dns,drop,tcp,flow,port-distribution,icmp,httpV2:exemplars=true;labelsContext=source_ip\,source_namespace\,source_workload\,destination_ip\,destination_namespace\,destination_workload\,traffic_direction}" \
  #  --set hostPort.enabled=true
# 1.15.1
helm install cilium cilium/cilium --version 1.16.1 \
  --namespace kube-system \
  --set hubble.relay.enabled=true \
  --set hubble.ui.enabled=true \
  --set operator.replicas=1 \
  --set tunnel=disabled \
  --set autoDirectNodeRoutes=true \
  --set hubble.tls.enabled=false \
  --set hubble.tls.auto.enabled=false \
  --set hubble.relay.tls.server.enabled=false \
  --set hubble.metrics.enabled="{dns,drop,tcp,flow,port-distribution,icmp,httpV2:exemplars=true;labelsContext=source_ip\,source_namespace\,source_workload\,destination_ip\,destination_namespace\,destination_workload\,traffic_direction}" 

echo "Install Hubble"
kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/v1.8/install/kubernetes/experimental-install.yaml

echo "Publish Hubble via NodePort"
CURRENT_PORT_TYPE=$(kubectl get svc -n kube-system hubble-ui -o jsonpath='{.spec.type}')
if [ "$CURRENT_PORT_TYPE" != "NodePort" ]; then
    kubectl delete svc -n kube-system hubble-ui
    kubectl expose deployment -n kube-system hubble-ui --type=NodePort --port=12000
fi

echo "Install latest Hubble CLI"
HUBBLE_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/hubble/master/stable.txt)
curl -LO "https://github.com/cilium/hubble/releases/download/$HUBBLE_VERSION/hubble-linux-amd64.tar.gz"
curl -LO "https://github.com/cilium/hubble/releases/download/$HUBBLE_VERSION/hubble-linux-amd64.tar.gz.sha256sum"
sha256sum --check hubble-linux-amd64.tar.gz.sha256sum
tar zxf hubble-linux-amd64.tar.gz
sudo mv hubble /usr/local/bin

PUBLI_IP=$(curl ifconfig.me)
HUBBLE_NODE_PORT=$(kubectl get svc -n kube-system hubble-ui -o jsonpath='{.spec.ports[0].nodePort}')
echo "Hubble exposed on: http://${PUBLI_IP}:${HUBBLE_NODE_PORT}"
cilium hubble enable --ui
cilium hubble port-forward&
sudo ufw allow 4245/tcp comment "Hubble Observability"
# Install ingress controller with NodePort service
# kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.40.2/deploy/static/provider/baremetal/deploy.yaml
# # Find port and ip address for Haproxy config
# PUBLIC_IP=$(ip route get 8.8.8.8  | awk ' /^[0-9]/ { print $7 }')
# INGRESS_HTTP_PORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o json | jq -r '.spec.ports[] | select(.name == "http") | .nodePort')
# INGRESS_HTTPS_PORT=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o json | jq -r '.spec.ports[] | select(.name == "https") | .nodePort')
# # Install Haproxy
# sudo add-apt-repository ppa:vbernat/haproxy-2.1 --yes
# sudo apt-get install haproxy -y
# # Configure Haproxy
# cat << EOF > /etc/haproxy/haproxy.cfg
# global
#     log /dev/log    local0
#     log /dev/log    local1 notice
#     user haproxy
#     group haproxy
#     maxconn 1000000
#     daemon
# defaults
#     log     global
#     mode    tcp
#     option  tcplog
#     option  dontlognull
#     timeout connect         10s
#     timeout client          1m
#     timeout server          1m
# frontend http_frontend
#     bind ${PUBLIC_IP}:80
#     default_backend http_backend
# backend http_backend
#     server ingress_http ${PUBLIC_IP}:${INGRESS_HTTP_PORT}
# frontend https_frontend
#     bind ${PUBLIC_IP}:443
#     default_backend https_backend
# backend https_backend
#     server ingress_https ${PUBLIC_IP}:${INGRESS_HTTPS_PORT}
# EOF
# # Reload Haproxy
# systemctl reload haproxy


echo "Create cert-manager namespace"
# kubectl create ns cert-manager

# echo "Install cert-manager with helm 3"
# helm repo add jetstack https://charts.jetstack.io
# helm install cert-manager \
#     jetstack/cert-manager \
#     --namespace cert-manager \
#     --version v1.0.4 \
#     --set installCRDs=true
    
# #echo "Install cert-manager without helm"
# #kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.0.4/cert-manager.yaml

# echo "Create test cert-manager"
# cat <<EOF | kubectl apply -f -
# apiVersion: v1
# kind: Namespace
# metadata:
#   name: cert-manager-test
# ---
# apiVersion: cert-manager.io/v1
# kind: Issuer
# metadata:
#   name: test-selfsigned
#   namespace: cert-manager-test
# spec:
#   selfSigned: {}
# ---
# apiVersion: cert-manager.io/v1
# kind: Certificate
# metadata:
#   name: selfsigned-cert
#   namespace: cert-manager-test
# spec:
#   dnsNames:
#     - example.com
#   secretName: selfsigned-cert-tls
#   issuerRef:
#     name: test-selfsigned
# EOF

# echo "Check the status of the newly created certificate"
# kubectl wait --for=condition=ready certificate -n cert-manager-test selfsigned-cert

# echo "Cleanup test namespace"
# kubectl delete ns cert-manager-test

# echo "Install kubectl plugin for cert-manager"
# curl -L -o kubectl-cert-manager.tar.gz https://github.com/jetstack/cert-manager/releases/download/v1.0.4/kubectl-cert_manager-linux-amd64.tar.gz
# tar xzf kubectl-cert-manager.tar.gz
# sudo mv kubectl-cert_manager /usr/local/bin

# echo "Create ClusterIssuers for email velizarx@gmail.com"
# cat <<EOF | kubectl apply -f -
# ---
# apiVersion: cert-manager.io/v1alpha2
# kind: ClusterIssuer
# metadata:
#   name: letsencrypt-staging
# spec:
#   acme:
#     server: https://acme-staging-v02.api.letsencrypt.org/directory
#     email: velizarx@gmail.com
#     privateKeySecretRef:
#       name: letsencrypt-staging
#     solvers:
#     - http01:
#         ingress:
#           class: nginx
# ---
# apiVersion: cert-manager.io/v1alpha2
# kind: ClusterIssuer
# metadata:
#   name: letsencrypt-prod
# spec:
#   acme:
#     server: https://acme-v02.api.letsencrypt.org/directory
#     email: velizarx@gmail.com
#     privateKeySecretRef:
#       name: letsencrypt-prod
#     solvers:
#     - http01:
#         ingress:
#           class: nginx
# EOF

# echo "Check the status of the newly created issuers"
# kubectl wait --for=condition=ready clusterissuer letsencrypt-prod
# kubectl wait --for=condition=ready clusterissuer letsencrypt-staging

# cilium hubble enable --ui
# HUBBLE_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/hubble/master/stable.txt)
# HUBBLE_ARCH=amd64
# if [ "$(uname -m)" = "aarch64" ]; then HUBBLE_ARCH=arm64; fi
# curl -L --fail --remote-name-all https://github.com/cilium/hubble/releases/download/$HUBBLE_VERSION/hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}
# sha256sum --check hubble-linux-${HUBBLE_ARCH}.tar.gz.sha256sum
# sudo tar xzvfC hubble-linux-${HUBBLE_ARCH}.tar.gz /usr/local/bin
# rm hubble-linux-${HUBBLE_ARCH}.tar.gz.sha256sum


# CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
# CLI_ARCH=amd64
# if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
# curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
# sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
# sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
# rm cilium-linux-${CLI_ARCH}.tar.gz.sha256sum

sudo sysctl fs.inotify.max_user_instances=8192
sudo sysctl fs.inotify.max_user_watches=524288
ulimit -Hn
sudo sysctl -p

echo "All ok ;)"

# rm /etc/kubernetes/pki/apiserver.* -f
# kubeadm init phase certs apiserver --apiserver-cert-extra-sans 172.17.0.1 --apiserver-cert-extra-sans 10.96.0.1 --apiserver-cert-extra-sans 172.16.0.41 --apiserver-cert-extra-sans 42.96.60.76 --apiserver-cert-extra-sans localhost
# kubeadm init phase certs apiserver --apiserver-cert-extra-sans 172.17.0.1 --apiserver-cert-extra-sans 10.96.0.1 --apiserver-cert-extra-sans 43.132.179.71 --apiserver-cert-extra-sans localhost
# journalctl -u kubelet
# kubectl edit -n kube-system daemonset.apps/calico-node
# kubectl edit -n kube-system deployment.apps/calico-kube-controllers
# kubectl edit cm coredns -n kube-system
#  kubectl edit cm -n kube-public cluster-info
# kubeadm join 43.132.179.71:6443 --token yeqs2y.s3lnganffjrp9t7r --discovery-token-ca-cert-hash sha256:f3a90eef654722dbed6575c8812f3be1ffd593dbdcb60b5989119b1c20a046e4 --v=6 --ignore-preflight-errors=all
# kubeadm join 43.132.179.71:6443 --token ybq4jm.p77wl7qhd4mqcop8 --discovery-token-ca-cert-hash sha256:f5c08bffa50831c4d7091c0d5b7b62794b8220d5153498c4e9f2c147e0eb6364 --v=6 --ignore-preflight-errors=all

# get the join command from the kube master
# CERT_HASH=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt \
# | openssl rsa -pubin -outform der 2>/dev/null \
# | openssl dgst -sha256 -hex \
# | sed 's/^.* //')
# TOKEN=$(kubeadm token list -o json | jq -r '.token' | head -1)
# IP=$(kubectl get nodes -lnode-role.kubernetes.io/master -o json \
# | jq -r '.items[0].status.addresses[] | select(.type=="InternalIP") | .address')
# PORT=6443
# echo "sudo kubeadm join $IP:$PORT \
# --token=$TOKEN --discovery-token-ca-cert-hash sha256:$CERT_HASH"

# sudo kubeadm join 43.154.94.12:6443 --token= --discovery-token-ca-cert-hash sha256:8bfcf7c2c8e90a461874c3a6e32b0308bc14995b29a83a3175b302ebfdd68d4c

# # cat /etc/docker/daemon.json
# {
#     "exec-opts": [
#         "native.cgroupdriver=cgroupfs"
#     ],
#     ......
# }
# # cat /var/lib/kubelet/config.yaml
# ......
# cgroupDriver: cgroupfs
# cgroupDriver: systemd
# ......
# Then reload config and restart docker and kubelet service.

# systemctl daemon-reload
# systemctl restart docker
# systemctl restart kubelet
# kubectl config set-context kind-us
# cilium clustermesh connect --context kind-us --destination-context kind-vn
# cilium connectivity test --context kind-vn --multi-cluster kind-us

# cilium clustermesh status --context kind-us --wait
# cilium clustermesh status --context kind-vn --wait

# cilium install \
#   --set cluster.name=us \
#   --set cluster.id=2 \
#   --set ipam.mode=kubernetes

# kubectl cluster-info --context kind-vn
# kubectl config use "${CLUSTER_1_CONTEXT}"
# kubectl cluster-info dump

# helm install cilium cilium/cilium --version 1.10.5 \
#    --namespace kube-system \
#    --set nodeinit.enabled=true \
#    --set kubeProxyReplacement=partial \
#    --set hostServices.enabled=false \
#    --set externalIPs.enabled=true \
#    --set nodePort.enabled=true \
#    --set hostPort.enabled=true \
#    --set cluster.name=vn \
#    --set cluster.id=1

# cilium install \
#   --set cluster.name=vn \
#   --set cluster.id=1 \
#   --set ipam.mode=kubernetes

# https://github.com/go-faster/cilium-mesh-testing/tree/main
# https://github.com/bmcustodio/kind-cilium-mesh


# cilium install \
#   --set cluster.name=kind-cilium-mesh-1 \
#   --set cluster.id=1 \
#   --set ipam.mode=kubernetes
#   cilium clustermesh status --context "mesh-1" --wait

#   cilium install \
#   --set cluster.name=kind-cilium-mesh-2 \
#   --set cluster.id=2 \
#   --set ipam.mode=kubernetes

# cilium clustermesh connect --context "kind-kind-cilium-mesh-1" --destination-context "kind-kind-cilium-mesh-2"

# cilium clustermesh connect --context kind-us --destination-context kind-eu

# cilium install --set cluster.name=kind-cilium-mesh-2 --set cluster.id=2 --set ipam.mode=kubernetes

# cilium clustermesh connect --context kind-kind-cilium-mesh-1 --destination-context kind-kind-cilium-mesh-2

# kubectl apply -f "./common/rebel-base.yaml" -f "https://raw.githubusercontent.com/cilium/cilium/v1.11.0-rc3/examples/kubernetes/clustermesh/global-service-example/cluster1.yaml"


# cilium connectivity test --context kind-kind-cilium-mesh-1 --multi-cluster kind-kind-cilium-mesh-2

# cilium clustermesh connect --context kind-us --destination-context kind-eu
# kubectl config use kind-us
# cilium install --set cluster.name=us --set cluster.id=1 --set ipam.mode=kubernetes
# kubectl config use kind-eu
# cilium install --set cluster.name=eu --set cluster.id=2 --set ipam.mode=kubernetes

# cilium connectivity test --context kind-us --multi-cluster kind-eu
# ilium clustermesh connect --context kind-us --destination-context kind-eu

# cilium clustermesh status --context kind-us --wait
# cilium clustermesh status --context kind-eu --wait
# kubectl get pod --all-namespaces -o wide
# helm install cilium cilium/cilium --version 1.16.1 --namespace kube-system --namespace kube-system \
#    --set hubble.relay.enabled=true \
#    --set hubble.enabled=true \
#    --set hubble.metrics.enabled="{dns,drop,tcp,flow,icmp,http}" \
#    --set hubble.relay.enabled=true \
#    --set hubble.ui.enabled=true \
#    --set hubble.ui.service.type=NodePort \
#    --set hubble.relay.service.type=NodePort \
#    --set hubble.ui.enabled=true \
#    --set hubble.metrics.dashboards.enabled=true \
#    --set hostServices.enabled=false \
#    --set externalIPs.enabled=true \
#    --set nodePort.enabled=true \
#    --set hostPort.enabled=true

# helm upgrade --install cilium cilium/cilium --version 1.13.1 \
#    --namespace cilium \
#    --set hubble.relay.enabled=true \
#    --set hubble.enabled=true \
#    --set hubble.metrics.enabled="{dns,drop,tcp,flow,icmp,http}" \
#    --set hubble.relay.enabled=true \
#    --set hubble.ui.enabled=true \
#    --set hubble.ui.service.type=NodePort \
#    --set hubble.relay.service.type=NodePort \
#    --set hubble.ui.enabled=true \
#    --set hubble.metrics.dashboards.enabled=true \
#    --set kubeProxyReplacement=partial \
#    --set hostServices.enabled=false \
#    --set externalIPs.enabled=true \
#    --set nodePort.enabled=true \
#    --set hostPort.enabled=true \
#    --set cluster.name=cluster2 \
#    --set cluster.id=2 
# helm upgrade cilium cilium/cilium --version 1.13.0 --namespace kube-system --reuse-values --set hubble.relay.enabled=true --set hubble.ui.enabled=true
# kubectl get pods -A
# https://stackoverflow.com/questions/70860152/how-to-delete-a-ingress-controller-on-kubernetes

# cilium install --set cluster.name=eu --set cluster.id=2 --set ipam.mode=kubernetes --set hubble.relay.enabled=true --set hubble.ui.enabled=true --set hubble.metrics.enabled="{dns,drop,tcp,flow,icmp,http}" --set hubble.metrics.dashboards.enabled=true --set externalIPs.enabled=true 
# https://gist.github.com/velp/151636fe01d8b8e3f9c626b30e3c2bc5

# kubectl get svc -n kube-system 

# cilium upgrade --version 1.15.1 \
#         --set ipam.mode=kubernetes \
#         --set routingMode=tunnel \
#         --set tunnelProtocol=vxlan \
#         --set ipam.operator.clusterPoolIPv4PodCIDRList=10.244.0.0/16 \
#         --set ipam.Operator.ClusterPoolIPv4MaskSize=24 \
#         --set ingressController.enabled=true \
#         --set ingressController.loadbalancerMode=shared \
#   --set ipam.mode=cluster-pool \
#   --set ipam.operator.clusterPoolIPv4PodCIDRList=10.66.0.0/16 \
#   --set ipam.operator.clusterPoolIPv4MaskSize=20 \
#   --set hubble.relay.enabled=true \
#   --set hubble.ui.enabled=true \
#   --set operator.replicas=10 \
#   --set tunnel=disabled \
#   --set ipv4NativeRoutingCIDR=10.66.0.0/16 \
#   --set autoDirectNodeRoutes=true \
#    --set hubble.tls.enabled=false \
#    --set hubble.tls.auto.enabled=false \
#    --set hubble.relay.tls.server.enabled=false \
#   --set hubble.metrics.enabled="{dns,drop,tcp,flow,port-distribution,icmp,httpV2:exemplars=true;labelsContext=source_ip\,source_namespace\,source_workload\,destination_ip\,destination_namespace\,destination_workload\,traffic_direction}" \
#   --set hubble.peerService.clusterDomain=cluster