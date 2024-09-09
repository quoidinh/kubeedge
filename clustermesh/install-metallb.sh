#!/usr/bin/env bash

set -e
set -o pipefail

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml --context=kind-cluster1
kubectl wait deployment -n metallb-system controller --for condition=Available=True --timeout=90s --context kind-cluster1
kubectl apply -f metallb-1.yaml --context=kind-cluster1

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml --context=kind-cluster2
kubectl wait deployment -n metallb-system controller --for condition=Available=True --timeout=90s --context kind-cluster2
kubectl apply -f metallb-2.yaml --context=kind-cluster2

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml --context=kind-cluster5
kubectl wait deployment -n metallb-system controller --for condition=Available=True --timeout=90s --context kind-cluster5
kubectl apply -f metallb-5.yaml --context=kind-cluster5

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml --context=kind-cluster6
kubectl wait deployment -n metallb-system controller --for condition=Available=True --timeout=90s --context kind-cluster6
kubectl apply -f metallb-6.yaml --context=kind-cluster6