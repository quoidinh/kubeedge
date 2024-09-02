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
sudo systemctl stop kubelet
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

echo "Installing Flannel..."
sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
sudo cat >  /run/flannel/subnet.env <<EOF
FLANNEL_NETWORK=10.0.0.0/16
FLANNEL_SUBNET=10.0.0.1/24
FLANNEL_MTU=1450
FLANNEL_IPMASQ=true
EOF
apt update
apt install containerd.io
sudo rm /etc/containerd/config.toml

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


helm repo add cilium https://helm.cilium.io/

cilium install --set cluster.name=cluster2 --set cluster.id=2 --set ipam.mode=kubernetes \
  --namespace kube-system \
   --set hubble.relay.enabled=true \
   --set hubble.enabled=true \
   --set hubble.relay.enabled=true \
   --set hubble.ui.enabled=true \
   --set hubble.ui.service.type=NodePort \
   --set hubble.relay.service.type=NodePort \
   --set hubble.ui.enabled=true \
   --set hubble.metrics.dashboards.enabled=true \
   --set hostServices.enabled=false \
   --set externalIPs.enabled=true \
   --set nodePort.enabled=true \
   --set hubble.tls.enabled=false \
   --set hubble.tls.auto.enabled=false \
   --set hubble.relay.tls.server.enabled=false \
   --set prometheus.enabled=true \
   --set operator.prometheus.enabled=true \
   --set hubble.metrics.enableOpenMetrics=true \
   --set hubble.metrics.enabled="{dns,drop,tcp,flow,port-distribution,icmp,httpV2:exemplars=true;labelsContext=source_ip\,source_namespace\,source_workload\,destination_ip\,destination_namespace\,destination_workload\,traffic_direction}" \
   --set hostPort.enabled=true

echo "Install latest Hubble CLI"
HUBBLE_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/hubble/master/stable.txt)
curl -LO "https://github.com/cilium/hubble/releases/download/$HUBBLE_VERSION/hubble-linux-amd64.tar.gz"
curl -LO "https://github.com/cilium/hubble/releases/download/$HUBBLE_VERSION/hubble-linux-amd64.tar.gz.sha256sum"
sha256sum --check hubble-linux-amd64.tar.gz.sha256sum
tar zxf hubble-linux-amd64.tar.gz
sudo mv hubble /usr/local/bin
sudo sysctl fs.inotify.max_user_instances=8192
sudo sysctl fs.inotify.max_user_watches=524288
ulimit -Hn
# sudo sysctl -p
# # sudo ip addr add 172.18.0.4/16 brd + dev br-2ecf150f8e48
# # sudo ip addr add 172.18.0.5/16 brd + dev br-f7fd5d8f1f88
# # sudo ip addr add 172.18.0.6/16 brd + dev br-f7fd5d8f1f88
# sudo ip addr add 172.18.130.218/16 brd + dev br-2ecf150f8e48

ip addr add 172.18.0.5/16 brd + dev br-7b088f685feb

# kubectl apply -f bgp-peering-policy.yml
# kubectl apply -f bgp-peering-policy-pool.yml


# # kind delete cluster --name cluster1
# # export KUBECONFIG=./kubeconfig-cluster1.yaml
# kind create cluster --name cluster1 --config kind-cluster.yaml
# kubectl config use kind-cluster1
# # helm install  cilium cilium/cilium --namespace kube-system -f quick-install-cluster1.yaml
 cilium install --set cluster.name=kind-2 --set cluster.id=2 --set ipam.mode=kubernetes \
  --namespace kube-system \
   --set hubble.relay.enabled=true \
   --set hubble.enabled=true \
   --set hubble.relay.enabled=true \
   --set hubble.ui.enabled=true \
   --set hubble.ui.service.type=NodePort \
   --set hubble.relay.service.type=NodePort \
   --set hubble.ui.enabled=true \
   --set hubble.metrics.dashboards.enabled=true \
   --set hostServices.enabled=false \
   --set externalIPs.enabled=true \
   --set nodePort.enabled=true \
   --set hubble.tls.enabled=false \
   --set hubble.tls.auto.enabled=false \
   --set hubble.relay.tls.server.enabled=false \
   --set prometheus.enabled=true \
   --set operator.prometheus.enabled=true \
   --set hubble.metrics.enableOpenMetrics=true \
   --set l7Proxy=true \
   --set externalWorkloads.enabled=true \
   --set clustermesh.useAPIServer=true \
   --set enable-bgp-control-plane.enabled=true \
   --set externalWorkloads.enabled=true \
   --set hubble.metrics.enabled="{dns,drop,tcp,flow,port-distribution,icmp,httpV2:exemplars=true;labelsContext=source_ip\,source_namespace\,source_workload\,destination_ip\,destination_namespace\,destination_workload\,traffic_direction}" \
   --set hostPort.enabled=true
# # cilium install --set cluster.name=cluster1 --set cluster.id=1 --set ipam.mode=kubernetes \
# #     --set hubble.relay.enabled=true \
# #    --set hubble.enabled=true \
# #    --set hubble.relay.enabled=true \
# #    --set hubble.ui.enabled=true \
# #    --set hubble.ui.service.type=NodePort \
# #    --set hubble.relay.service.type=NodePort \
# #    --set hubble.metrics.dashboards.enabled=true \
# #    --set hostServices.enabled=false \
# #    --set externalIPs.enabled=true \
# #    --set nodePort.enabled=true \
# #    --set hubble.tls.enabled=false \
# #    --set hubble.tls.auto.enabled=false \
# #    --set hubble.relay.tls.server.enabled=false \
# #    --set l2announcements.enabled=true \
# #    --set autoDirectNodeRoutes=true \
# #    --set operator.replicas=1 \
# #    --set ipv4.enabled=true  \
# #    --set ipv6.enabled=false  \
# #    --set loadBalancer.mode=hybrid  \
# #    --set routingMode=native  \
# #    --set k8sClientRateLimit.qps=50  \
# #    --set k8sClientRateLimit.burst=100  \
# #    --set l2announcements.leaseDuration=3s  \
# #    --set l2announcements.leaseRenewDeadline=1s  \
# #    --set l2announcements.leaseRetryPeriod=200ms  \
# #    --set ingressController.Enabled=true  \
# #    --set enable-bgp-control-plane.enabled=true \
# #    --set ipam.operator.clusterPoolIPv4PodCIDRList=172.18.0/24  \
# #    --set ipv4NativeRoutingCIDR=10.0.0.0/16 \
# #    --set prometheus.enabled=true \
# #    --set hubble.metrics.enableOpenMetrics=true \
# #    --set operator.prometheus.enabled=true \
# #    --set ingressController.Enabled=true  \
# #    --set ingressController.loadbalancerMode=dedicated \
# #    --set hubble.metrics.enabled="{dns,drop,tcp,flow,port-distribution,icmp,httpV2:exemplars=true;labelsContext=source_ip,source_namespace,source_workload,destination_ip,destination_namespace,destination_workload,traffic_direction}" \
# #    --set hostPort.enabled=true
#  --set kubeProxyReplacement=strict \
#    --set l7Proxy=false \
#    --set k8sServiceHost=x.x.x.x \
#    --set k8sServicePort=6443 \
#    --set cluster.name=cluster01 \
#    --set cluster.id=1 \
#    --set externalWorkloads.enabled=true \
#    --set clustermesh.useAPIServer=true

# cilium clustermesh enable --service-type NodePort
# # cilium clustermesh enable --service-type LoadBalancer
# cilium hubble enable --ui

# kind delete cluster --name cluster2
# # export KUBECONFIG=./kubeconfig-cluster2.yaml
# kind create cluster --name cluster2 --config kind-cluster2.yaml
# kubectl config use kind-cluster2
# # helm install  cilium cilium/cilium --namespace kube-system -f quick-install-cluster2.yaml
# cilium install --set cluster.name=cluster4 --set cluster.id=4 --set ipam.mode=kubernetes \
#   --namespace kube-system \
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
#    --set hubble.tls.enabled=false \
#    --set hubble.tls.auto.enabled=false \
#    --set hubble.relay.tls.server.enabled=false \
#    --set prometheus.enabled=true \
#    --set operator.prometheus.enabled=true \
#    --set hubble.metrics.enableOpenMetrics=true \
#    --set hubble.metrics.enabled="{dns,drop,tcp,flow,port-distribution,icmp,httpV2:exemplars=true;labelsContext=source_ip\,source_namespace\,source_workload\,destination_ip\,destination_namespace\,destination_workload\,traffic_direction}" \
#    --set hostPort.enabled=true

   
# cilium install --set cluster.name=cluster2 --set cluster.id=2 --set ipam.mode=kubernetes \
#    --set hubble.relay.enabled=true \
#    --set hubble.enabled=true \
#    --set hubble.relay.enabled=true \
#    --set hubble.ui.enabled=true \
#    --set hubble.ui.service.type=NodePort \
#    --set hubble.relay.service.type=NodePort \
#    --set hubble.metrics.dashboards.enabled=true \
#    --set hostServices.enabled=false \
#    --set externalIPs.enabled=true \
#    --set nodePort.enabled=true \
#    --set hubble.tls.enabled=false \
#    --set hubble.tls.auto.enabled=false \
#    --set hubble.relay.tls.server.enabled=false \
#    --set l2announcements.enabled=true \
#    --set autoDirectNodeRoutes=true \
#    --set operator.replicas=1 \
#    --set ipv4.enabled=true  \
#    --set ipv6.enabled=false  \
#    --set loadBalancer.mode=hybrid  \
#    --set routingMode=native  \
#    --set k8sClientRateLimit.qps=50  \
#    --set k8sClientRateLimit.burst=100  \
#    --set l2announcements.leaseDuration=3s  \
#    --set l2announcements.leaseRenewDeadline=1s  \
#    --set l2announcements.leaseRetryPeriod=200ms  \
#    --set ingressController.Enabled=true  \
#    --set enable-bgp-control-plane.enabled=true \
#    --set ipam.operator.clusterPoolIPv4PodCIDRList=172.18.0/24  \
#    --set ipv4NativeRoutingCIDR=10.0.0.0/16 \
#    --set prometheus.enabled=true \
#    --set hubble.metrics.enableOpenMetrics=true \
#    --set operator.prometheus.enabled=true \
#    --set ingressController.Enabled=true  \
#    --set ingressController.loadbalancerMode=dedicated \
#    --set hubble.metrics.enabled="{dns,drop,tcp,flow,port-distribution,icmp,httpV2:exemplars=true;labelsContext=source_ip,source_namespace,source_workload,destination_ip,destination_namespace,destination_workload,traffic_direction}" \
#    --set hostPort.enabled=true

# cilium clustermesh enable --context kind-cluster1 --service-type NodePort
# cilium clustermesh enable --service-type NodePort
# cilium clustermesh enable --service-type LoadBalancer

# cilium hubble enable --ui


# --set operator.replicas=1 \
# --set ipv4.enabled=true  \
# --set loadBalancer.mode=dsr  \
# --set loadBalancer.mode=hybrid \
# --set routingMode=native  \
# --set autoDirectNodeRoutes=true  \
# --set l2announcements.enabled=true  \
# --set kubeProxyReplacement=true  \
# --set k8sClientRateLimit.qps=50  \
# --set k8sClientRateLimit.burst=100  \
# --set l2announcements.leaseDuration=3s  \
# --set l2announcements.leaseRenewDeadline=1s  \
# --set l2announcements.leaseRetryPeriod=200ms  \
# --set ingressController.Enabled=true  \
# --set enable-bgp-control-plane.enabled=true \
# --set ipam.operator.clusterPoolIPv4PodCIDRList=172.18.103.0/24 \
# --set ipv4NativeRoutingCIDR=10.0.0.0/16  \
 # --set ipam.operator.clusterPoolIPv4MaskSize=26 \
#  --set 'cni.binPath=/usr/libexec/cni' \
# --set k8sServiceHost=192.168.0.105  \
# --set k8sServicePort=6443 


# cilium clustermesh connect --context kind-kind-1 --destination-context kind-kind-2
# cilium clustermesh connect --context kind-cluster2 --destination-context kind-cluster3
# cilium clustermesh connect --context kind-cluster3 --destination-context kind-cluster4
# cilium clustermesh connect --context kind-cluster4 --destination-context kind-cluster1

# export KUBECONFIG=./kubeconfig-cluster1.yaml:./kubeconfig-cluster2.yaml:./kubeconfig-cluster3.yaml:./kubeconfig-cluster4.yaml:./kubeconfig-cluster5.yaml
# kubectl config view --flatten > merged-kubeconfig.yaml
# # Next set the KUBECONFIG to the newly created merged kubeconfig.
# export KUBECONFIG=./merged-kubeconfig.yaml
# kubectl config get-contexts
# kubectl config get-clusters

# kubectl config use kind-cluster1
# kubectl delete -f https://raw.githubusercontent.com/bmcustodio/kind-cilium-mesh/master/common/rebel-base.yaml -f https://raw.githubusercontent.com/cilium/cilium/v1.11.0-rc3/examples/kubernetes/clustermesh/global-service-example/cluster2.yaml
# kubectl config use kind-cluster2
# kubectl delete -f https://raw.githubusercontent.com/bmcustodio/kind-cilium-mesh/master/common/rebel-base.yaml -f https://raw.githubusercontent.com/cilium/cilium/v1.11.0-rc3/examples/kubernetes/clustermesh/global-service-example/cluster1.yaml
# nohup kubectl port-forward service//nginx-deployment --namespace=default --address 0.0.0.0 8081:80 &
# kubectl run --restart Never --rm -it --image giantswarm/tiny-tools tinytools -- /bin/sh -c 'for i in $(seq 1 20); do curl http://global-base; done'

cilium status 
# cilium clustermesh status --context kind-kind-1 --wait
# cilium clustermesh status --context kind-cluster2 --wait

# cilium clustermesh enable --context kind-kind-1 --service-type NodePort
# cilium clustermesh enable --context kind-cluster2 --service-type NodePort

echo "Install Hubble ui"
# # cilium hubble ui
# cilium hubble port-forward &
sudo ufw allow 4245/tcp comment "Hubble Observability"
# #  lsof-i :4245
# # # kill -9 
# kubectl patch svc hubble-ui -n kube-system -p '{"spec": {"type": "LoadBalancer", "externalIPs":["172.18.0.4"]}}'
# kubectl patch svc hubble-relay -n kube-system -p '{"spec": {"type": "LoadBalancer", "externalIPs":["172.18.0..4"]}}'
# nohup kubectl port-forward -n kube-system svc/hubble-ui --address 0.0.0.0 4245:80 &

# echo "cilium-monitoring"
# kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/1.16.1/examples/kubernetes/addons/prometheus/monitoring-example.yaml
# kubectl delete -f https://raw.githubusercontent.com/cilium/cilium/1.16.1/examples/kubernetes/addons/prometheus/monitoring-example.yaml
# kubectl apply -f monitor-grafana-promethus-yugabyte.yaml
# # kubectl delete -f monitor-grafana-promethus-yugabyte.yaml
# nohup kubectl -n cilium-monitoring port-forward service/prometheus --address 0.0.0.0 9090:9090 &
# nohup kubectl -n cilium-monitoring port-forward service/grafana --address 0.0.0.0 3000:3000 &


# echo "install yugabytedb"
# helm repo add yugabytedb https://charts.yugabyte.com
# kubectl apply -f yugabyte-statefulset.yaml
# # kubectl delete -f yugabyte-statefulset.yaml
# # kubectl apply -f https://raw.githubusercontent.com/YugaByte/yugabyte-db/master/cloud/kubernetes/yugabyte-statefulset.yaml
# nohup kubectl port-forward service/yb-tservers --namespace=default --address 0.0.0.0 5433:5433 &
# nohup kubectl port-forward service/yb-tservers --namespace=default --address 0.0.0.0 9000:9000 &
# nohup kubectl port-forward service/yb-master-ui --namespace=default --address 0.0.0.0 7000:7000 &
# kubectl scale statefulset yb-tserver --replicas=8
# kubectl scale statefulset yb-master --replicas=8

# echo "install kubernetes-dashboard"
# helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
# helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard 
# nohup kubectl -n default port-forward svc/kubernetes-dashboard-kong-proxy --address 0.0.0.0  8443:443&
# kubectl apply -f create-service-cccount.yaml
# kubectl apply -f create-cluster-role-binding.yaml
# kubectl -n default create token admin-user
# # eyJhbGciOiJSUzI1NiIsImtpZCI6IjV4MHIxNVhCVy1tUG41Q2ZSTmJRQ1RMVmpHTkdvNjdaMG5SRFdwS3FhS2MifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiXSwiZXhwIjoxNzI0NzI3MjQwLCJpYXQiOjE3MjQ3MjM2NDAsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwianRpIjoiYzQyODFiNzQtMzE0NC00ODhlLThmN2UtNWRhNjZkZTRiMWRhIiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJkZWZhdWx0Iiwic2VydmljZWFjY291bnQiOnsibmFtZSI6ImFkbWluLXVzZXIiLCJ1aWQiOiIxYmIwODA4Yy03MTA5LTQwMzEtOTA4MS1mZWZkMmU0MGNjZGMifX0sIm5iZiI6MTcyNDcyMzY0MCwic3ViIjoic3lzdGVtOnNlcnZpY2VhY2NvdW50OmRlZmF1bHQ6YWRtaW4tdXNlciJ9.iQTjbuF862nt_D_PmzrC21OnmTj_mEA6p8D5a4MLYzZQXeDcystWWotO-AqxLDZ0mM1A9IBnNXNh5VNy--QV8ZB0cOJwSsifoJ7CjJ6ftdC4VLBU21hi8C6eCv9jWPHlDFWMqOtTD1JJbJV3k705ndwmI42RGWCgDYV82eJQZeSG2VP5vK1CRdOXMbiKC3xHQhBFIB0xL1IF8qEF5J8uAwYNJVs1p1I-MiR4stTTF71EKNrW3TSHopR1bgh4wybaVf203Gq8-H6OlBoUqz40X1_bj2i6duvI49XJiUTQt1eLkr-TokoXLswk-iS3HviV7bXQ-SXDXpS8vTTRk0tEVA

# echo "install sample application"
# kubectl apply -f app-nginx1.yaml
# kubectl describe deploy test-app
# kubectl autoscale deployment test-app --cpu-percent=15 --min=1 --max=20
# # kubectl scale statefulset test-app --replicas=3
# nohup kubectl port-forward service/test-app --namespace=default --address 0.0.0.0 9999:8080 &

# helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
# helm repo update
# kubectl create namespace ingress-nginx
# helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --set controller.metrics.enabled=true --set-string controller.podAnnotations."prometheus\.io/scrape"="true" --set-string controller.podAnnotations."prometheus\.io/port"="10254"
# kubectl get service --namespace ingress-nginx ingress-nginx-controller --output wide 
# kubectl get ingress -n ingress-nginx
# kubectl get services -n ingress-nginx


# echo "install locust"
# kubectl create deployment locust --image paultur/locustproject:latest
# kubectl expose deployment locust --type LoadBalancer --port 81 --target-port 8089
# nohup kubectl port-forward service/locust --namespace=default --address 0.0.0.0 9998:81 &
# kubectl patch svc  clustermesh-apiserver -n kube-system -p '{"spec": {"type": "NodePort", "externalIPs":["172.16.0.113"]}}'
kubectl get pods --all-namespaces
kubectl get nodes,pods,svc,deploy -A
echo "All ok ;)"

# https://docs.coreweave.com/coreweave-kubernetes/getting-started/advanced-kubeconfig-environments
# kubectl patch svc  clustermesh-apiserver -n kube-system -p '{"spec": {"type": "NodePort", "externalIPs":["172.18.0.5"]}}'
# kubectl config use kind-cluster1
# kubectl patch svc yb-master-ui -n default -p '{"spec": {"type": "LoadBalancer", "externalIPs":["172.18.0.4"]}}'
# kubectl patch svc yb-db-service -n default -p '{"spec": {"type": "LoadBalancer", "externalIPs":["172.18.0.4"]}}'
# kubectl get svc

# kubectl config use kind-cluster2
# kubectl patch svc yb-master-ui -n default -p '{"spec": {"type": "LoadBalancer", "externalIPs":["172.18.0.4"]}}'
# kubectl patch svc yb-db-service -n default -p '{"spec": {"type": "LoadBalancer", "externalIPs":["172.18.0.4"]}}'
# kubectl get svc

# helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
# helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard 
#    --create-namespace --namespace kubernetes-dashboard 
#    --set=nginx.enabled=false 
#    --set=cert-manager.enabled=false
#  nohup kubectl -n default port-forward svc/kubernetes-dashboard-kong-proxy --address 0.0.0.0 8443:443 &
# # create two files create-service-cccount.yaml

# apiVersion: v1
# kind: ServiceAccount
# metadata:
#   name: admin-user
#   namespace: default

# # and create-cluster-role-binding.yaml

# apiVersion: rbac.authorization.k8s.io/v1
# kind: ClusterRoleBinding
# metadata:
#   name: admin-user
# roleRef:
#   apiGroup: rbac.authorization.k8s.io
#   kind: ClusterRole
#   name: cluster-admin
# subjects:
# - kind: ServiceAccount
#   name: admin-user
#   namespace: default
# then run

# kubectl apply -f create-service-cccount.yaml
# kubectl apply -f create-cluster-role-binding.yaml
# kubectl -n default create token admin-user


# kubectl -n default get svc/service-gp-peering-pool -o jsonpath='{.status.conditions}' | jq


# nohup  kubectl port-forward svc/nginx-svc --namespace=default --address 0.0.0.0 8081:80 &
# nohup kubectl port-forward service/nginx-svc --namespace=default 8081:80 &
# nohup kubectl port-forward service/rebel-base --namespace=default --address 0.0.0.0 8081:80 &



# kubectl get pods


# nohup kubectl port-forward service/yb-db-service --namespace=default --address 0.0.0.0 5433:5433 &

# nohup kubectl port-forward service/yb-db-service --namespace=default --address 0.0.0.0 9000:9000 &
# nohup kubectl port-forward service/yb-master-ui --namespace=default --address 0.0.0.0 7000:7000 &

# kubectl create namespace yb-platform
# helm install yb-demo yugabytedb/yugabyte --version 2.21.1 --set resource.master.requests.cpu=0.5,resource.master.requests.memory=0.5Gi,resource.tserver.requests.cp=0.5,resource.tserver.requests.memory=0.5Gi,replicas.master=3,replicas.tserver=3  --namespace yb-platform
# # helm upgrade --install  yb-demo yugabytedb/yugabyte --version 2.21.1 --set resource.master.requests.cpu=0.5,resource.master.requests.memory=0.5Gi,resource.tserver.requests.cp=0.5,resource.tserver.requests.memory=0.5Gi,replicas.master=3,replicas.tserver=3  --namespace yb-platform
# nohup kubectl port-forward service/yyb-db-service --namespace=default --address 0.0.0.0 15433:15433 &
# nohup kubectl port-forward service/yb-db-service --namespace=default --address 0.0.0.0 9000:9000 &
# nohup kubectl port-forward service/yb-master-ui --namespace=default --address 0.0.0.0 7000:7000 &

# nohup kubectl port-forward service/nginx --namespace=default --address 0.0.0.0 9999:80 &
# nohup kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy  --address 0.0.0.0 8443:443 &
# kubectl scale --replicas=20 deployment nginx -n default
# docker exec -i yugabytedb_node1 yb-admin -master_addresses yugabytedb_node1:7100  setup_universe_replication 4637d6fe83ba442ea18d1724d8e494e4 yugabytedb_node2:9000 000000010000300080000000000000af	
# yb-admin -master_addresses yb-master-0.yb-masters.yb-platform.svc.cluster.local:7000,yb-master-1.yb-masters.yb-platform.svc.cluster.local:7000,yb-master-2.yb-masters.yb-platform.svc.cluster.local:7000 modify_placement_info aws.us_west.zone-a:1,aws.us_central.zone-b:1,aws.us_east.zone-c:1 3
# https://www.bookstack.cn/read/yugabyte-2.1/7292656daa1dacc0.md
# yb-admin -master_addresses <consumer-master-addresses> setup_universe_replication <producer-universe_uuid> <producer_master_addresses> <producer-table-ids>
# yb-admin -master_addresses 127.0.0.2:7100 setup_universe_replication 7acd6399-657d-42dc-a90a-646869898c2d 127.0.0.1:7100 000030a9000030008000000000004000




# helm status yb-demo -n yb-platform
# NAME: yb-demo
# LAST DEPLOYED: Wed Aug 21 12:28:19 2024
# NAMESPACE: yb-platform
# STATUS: deployed
# REVISION: 2
# TEST SUITE: None
# NOTES:
# 1. Get YugabyteDB Pods by running this command:
#   kubectl --namespace yb-platform get pods

# 2. Get list of YugabyteDB services that are running:
#   kubectl --namespace yb-platform get services

# 3. Get information about the load balancer services:
#   kubectl get svc --namespace yb-platform

# 4. Connect to one of the tablet server:
#   kubectl exec --namespace yb-platform -it yb-tserver-0 bash

# 5. Run YSQL shell from inside of a tablet server:
#   kubectl exec --namespace yb-platform -it yb-tserver-0 -- /home/yugabyte/bin/ysqlsh -h yb-tserver-0.yb-tservers.yb-platform

# kubectl  get storageClass
# kubectl scale statefulset vn-yugabyte-yb-tserver --replicas 3 --namespace yb-platform --context vn

# kubectl create namespace yb-platform
# helm install yw-test yugabytedb/yugaware -n yb-platform \
#    --version 2.21.1 \
#    --set image.repository=quay.io/yugabyte/yugaware-ubi \
#    --set ocpCompatibility.enabled=true --set rbac.create=false \
#    --set securityContext.enabled=false --wait
# kubectl apply -f - <<EOF
# kind: ClusterRoleBinding
# apiVersion: rbac.authorization.k8s.io/v1
# metadata:
#   name: yw-test-cluster-monitoring-view
#   labels:
#     app: yugaware
# subjects:
# - kind: ServiceAccount
#   name: yw-test
#   namespace: yb-platform
# roleRef:
#   kind: ClusterRole
#   name: cluster-monitoring-view
#   apiGroup: rbac.authorization.k8s.io
# EOF
# helm status yw-test -n yb-platform
# kubectl get svc -n yb-platform
# kubectl get pods -n yb-platform
# helm delete yw-test -n yb-platform

# git clone https://github.com/yugabyte/yugabyte-k8s-operator
# cd yugabyte-k8s-operator
# kubectl create ns operator-test
# kubectl apply -f ./crd/concatenated_crd.yaml
# cd ./chart
# helm install . -n operator-test --debug --timeout 3600s --set rbac.create=true --set kubernetesOperatorNamespace=operator-test --generate-name 
# sudo cat > ./demo-universe.yaml <<EOF
# apiVersion: operator.yugabyte.io/v1alpha1
# kind: YBUniverse
# metadata:
#   name: demo-test
# spec:
#   numNodes: 1
#   replicationFactor: 1
#   enableYSQL: true
#   enableNodeToNodeEncrypt: true
#   enableClientToNodeEncrypt: true
#   enableLoadBalancer: true
#   ybSoftwareVersion: "2024.1.0-b2"
#   enableYSQLAuth: false
#   enableYCQL: true
#   enableYCQLAuth: false
#   gFlags:
#     tserverGFlags: {}
#     masterGFlags: {}
# EOF

#   deviceInfo:
#     volumeSize: 100
#     numVolumes: 1
#     storageClass: "yb-standard"

# kubectl apply -f demo-universe.yaml -n yb-demo
# helm status yb-demo -n yb-demo
# kubectl get ybuniverse  -n yb-operator



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


# echo "Create cert-manager namespace"
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
# kubectl cluster-info --context kind-vn
# kubectl config use "${CLUSTER_1_CONTEXT}"
# kubectl cluster-info dump
# kubectl get pod --all-namespaces -o wide
# kubectl get svc -n kube-system 
# kubectl get pods -A



# kubectl scale statefulset east-yugabyte-yb-tserver \
#     --replicas 0 --namespace ybdb \
#     --context east

# helm delete my-yugaware -n yb-demo
# https://docs.yugabyte.com/preview/yugabyte-platform/prepare/server-nodes-software/software-kubernetes/
# https://stackoverflow.com/questions/48857092/how-to-expose-nginx-on-public-ip-using-nodeport-service-in-kubernetes




# https://7thzero.com/blog/minikube-cilium-on-ubuntu-18-04
#
# Cilium stuff
#   NOTE: This is pulling the Kubernetes 1.10 yaml. You may need to update this based on your chosen Kubernetes version
# kubectl create -n kube-system -f https://raw.githubusercontent.com/cilium/cilium/1.3.0/examples/kubernetes/addons/etcd/standalone-etcd.yaml
# kubectl create -f https://raw.githubusercontent.com/cilium/cilium/1.3.0/examples/kubernetes/1.10/cilium.yaml
# https://picluster.ricsanfre.com/docs/cilium/

# https://github.com/bmcustodio/kind-cilium-mesh/blob/master/README.md
# https://github.com/dennyzhang/kubernetes-yaml-templates