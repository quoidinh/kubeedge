# PeerTube on Kubernetes

![Logo](peertube-on-kubernetes.png)

Deploy [PeerTube](https://joinpeertube.org/) on a [Kubernetes](https://kubernetes.io/)

### 📺

> Peertube is the free and decentralized alternative to video platforms

### ☸

> Kubernetes  is an open-source system for automating deployment, scaling,
> and management of containerized applications.

| ⚠  | This deployment is in beta level, use at your own risk, feedback welcome |
|----|--------------------------------------------------------------------------|

## Requirements

* Access to a Kubernetes Cluster
* Access to an S3 type bucket (minio, seaweedfs, AWS, OVH's Object store, etc)
* Access to a postgresql database (not included in the kubernetes deployment)

## How to

Modify secrets (postgresql credentials, s3 credentials)

```shell
cp kustomization.yaml.example kustomization.yaml
```

With a valid `kubectl` and `KUBECONFIG` run the following commands :

```shell

kubectl apply -n peertube -k .
kubectl apply -n peertube -f deployment.yml  pvc.yml service.yml
```

If you want to configure an nginx-ingress, edit `ingress.yml` with your domain name :

```shell
cp ingress.yml.example ingress.yml
kubectl apply -n peertube -f ingress.yml
```

## Projects under the hood


* https://github.com/efrecon/docker-s3fs-client for s3fs side car
* https://github.com/wader/postfix-relay for postfix email
* https://hub.docker.com/_/redis/ for redis server

## Similar

* https://github.com/coopgo/peertube-k8s

