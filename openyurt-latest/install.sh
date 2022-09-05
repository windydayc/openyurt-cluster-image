#!/bin/bash

echo "[INFO] Label master node: openyurt.io/is-edge-worker=false"
master_node_name=`echo $HOSTNAME | awk '{print tolower($0)}'`
kubectl label node ${master_node_name} openyurt.io/is-edge-worker=false

echo "[INFO] Install flannel"
kubectl apply -f manifests/kube-flannel.yaml

echo "[INFO] Adjust kube-controller-manager"
./kube-controller-manager.sh
echo "kube-controller-manager adjustment completed"

echo "[INFO] Install yurt-tunnel-dns"
kubectl apply -f manifests/yurt-tunnel-dns.yaml

echo "[INFO] Adjust kube-apiserver"
./kube-apiserver.sh

echo "[INFO] Adjust coreDNS"
kubectl apply -f manifests/coredns.yaml
kubectl scale --replicas=0 deployment/coredns -n kube-system
kubectl annotate svc kube-dns -n kube-system openyurt.io/topologyKeys='openyurt.io/nodepool'

echo "[INFO] Adjust kube-proxy"
kubectl get cm -n kube-system kube-proxy -oyaml | sed 's|kubeconfig: \/var\/lib\/kube-proxy\/kubeconfig.conf|#kubeconfig: \/var\/lib\/kube-proxy\/kubeconfig.conf|g' - | kubectl apply -f -

echo "[INFO] Install helm"
if ! [[ -x `command -v helm` ]]; then
  echo "helm is not installed, start to install helm"
  tar -zxvf helm-v3.9.4-linux-amd64.tar.gz && cp linux-amd64/helm /usr/bin && chmod +x /usr/bin/helm
  echo "successfully installed helm v3.9.4"
else
  echo "helm already exists, skip helm installation"
fi

echo "[INFO] Add openyurt helm repo"
helm repo add openyurt https://openyurtio.github.io/openyurt-helm && helm repo update

echo "[INFO] Install yurt-controller-manager, yurt-tunnel-server, yurt-tunnel-agent, yurthub-cfg"
helm upgrade --install openyurt openyurt/openyurt -n kube-system -f manifests/openyurt-values.yaml

echo "[INFO] Install yurt-app-manager"
helm upgrade --install yurt-app-manager openyurt/yurt-app-manager -n kube-system -f manifests/yurt-app-manager-values.yaml

echo "[INFO] OpenYurt is successfully installed"