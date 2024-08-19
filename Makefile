.DEFAULT_TARGET: all

all: k8s/kind cilium/install cilium/wait cilium/connect cilium/wait k8s/apps k8s/wait

k8s/kind:
	kind create cluster --config=kind/cluster1.yaml --name cluster1
	kind create cluster --config=kind/cluster2.yaml --name cluster2
	kind create cluster --config=kind/cluster3.yaml --name cluster3

k8s/apps:
	kubectl --context kind-cluster1 apply -f apps/cluster1.yaml
	kubectl --context kind-cluster2 apply -f apps/cluster2.yaml
	kubectl --context kind-cluster3 apply -f apps/cluster3.yaml

k8s/wait:
	kubectl --context kind-cluster1 wait deploy/rebel-base --for=condition=Available --timeout=300s
	kubectl --context kind-cluster1 wait deploy/x-wing --for=condition=Available --timeout=300s
	kubectl --context kind-cluster2 wait deploy/rebel-base --for=condition=Available --timeout=300s
	kubectl --context kind-cluster2 wait deploy/x-wing --for=condition=Available --timeout=300s
	kubectl --context kind-cluster3 wait deploy/x-wing --for=condition=Available --timeout=300s

cilium/install:
	# cilium --context kind-cluster1 install --version v1.15.4 --values cilium/cluster1.yaml 
	# cilium --context kind-cluster2 install --version v1.15.4 --values cilium/cluster2.yaml 
	# cilium --context kind-cluster3 install --version v1.15.4 --values cilium/cluster3.yaml 
	cilium install --set cluster.name=kind-cluster1 --set cluster.id=1 --set ipam.mode=kubernetes
	cilium install --set cluster.name=kind-cluster2 --set cluster.id=2 --set ipam.mode=kubernetes
	cilium install --set cluster.name=kind-cluster3 --set cluster.id=3 --set ipam.mode=kubernetes
	cilium clustermesh --context kind-cluster1 enable --service-type NodePort
	cilium clustermesh --context kind-cluster2 enable --service-type NodePort
	cilium clustermesh --context kind-cluster3 enable --service-type NodePort
cilium/wait:
	cilium --context kind-cluster1 status --wait --wait-duration 10m
	cilium --context kind-cluster2 status --wait --wait-duration 10m
	cilium --context kind-cluster3 status --wait --wait-duration 10m
	cilium --context kind-cluster1 clustermesh status --wait
	cilium --context kind-cluster2 clustermesh status --wait
	cilium --context kind-cluster3 clustermesh status --wait

cilium/connect:
	cilium clustermesh connect --context kind-cluster1 --destination-context kind-cluster2
	cilium clustermesh connect --context kind-cluster1 --destination-context kind-cluster3
	cilium clustermesh connect --context kind-cluster2 --destination-context kind-cluster3

build_deathstar_image:
	docker build -t deathstar:latest -f Dockerfile.deathstar .

build_tiefighter_image:
	docker build -t tiefighter:latest -f Dockerfile.tiefighter .

deploy_cluster_1:
	kind load --name=kind-cluster1 docker-image deathstar:latest
	kind load --name=kind-cluster1 docker-image tiefighter:latest
	kubectl --context kind-kind-cluster1 apply -f cilium/cluster1.yaml
	kubectl --context kind-kind-cluster1 wait -n default --for=condition=available deployment/deathstar

deploy_cluster_2:
	kind load --name=kind-cluster2 docker-image deathstar:latest
	kind load --name=kind-cluster2 docker-image tiefighter:latest
	kubectl --context kind-kind-cluster2 apply -f cilium/cluster2.yaml
	kubectl --context kind-kind-cluster2 wait -n default --for=condition=available deployment/deathstar

deploy_cluster_3:
	kind load --name=kind-cluster3 docker-image deathstar:latest
	kind load --name=kind-cluster3 docker-image tiefighter:latest
	kubectl --context kind-kind-cluster3 apply -f cilium/cluster3.yaml
	kubectl --context kind-kind-cluster3 wait -n default --for=condition=available deployment/deathstar

.PHONY: clean
clean:
	kind delete cluster --name cluster1
	kind delete cluster --name cluster2
	kind delete cluster --name cluster3
setup_monitoring:
	cd _monitoring && docker-compose up -d --wait
	./_hack/wait.sh http://localhost:9090/-/healthy
	./_hack/wait.sh http://localhost:3000/api/health
