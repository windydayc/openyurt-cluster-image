#!/bin/bash

yurt_tunnel_dns_clusterip=`kubectl get svc yurt-tunnel-dns -n kube-system -o jsonpath='{.spec.clusterIP}'`

sed -i '/dnsPolicy:/d' /etc/kubernetes/manifests/kube-apiserver.yaml
sed -i '/spec:/a \ \ dnsPolicy: "None"' /etc/kubernetes/manifests/kube-apiserver.yaml

sed -i '/spec:/a \
  dnsConfig:\
    nameservers:\
    \- '${yurt_tunnel_dns_clusterip}'\
    searches:\
    \- kube-system.svc.cluster.local\
    \- svc.cluster.local\
    \- cluster.local\
    options:\
    \- name: ndots\
      value: "5"' /etc/kubernetes/manifests/kube-apiserver.yaml

sed -i 's/--kubelet-preferred-address-types=.*$/--kubelet-preferred-address-types=Hostname,InternalIP,ExternalIP/g' /etc/kubernetes/manifests/kube-apiserver.yaml

function wait_condition_ready() {

    local cmd=$1
    local res=$2
    local timeout=${3:-300}

    local cnt=0

    while [[ $cnt -lt $timeout ]]; do

        tmp=`${cmd} 2>/dev/null`

        if [[ $res == $tmp ]]; then
            return 0
        fi

        sleep 1
        let cnt++
    done

    return 1
}

master_node_name=`echo $HOSTNAME | awk '{print tolower($0)}'`
cmd="kubectl get pod kube-apiserver-${master_node_name} -n kube-system -o=jsonpath={.status.phase}"

echo "Waiting for kube-apiserver to restart..."
wait_condition_ready "$cmd" "Running" 300

if [[ $? != 0 ]]
then
    echo "timed out waiting for the kube-apiserver to restart"
    exit 1
fi

echo "Kube-apiserver has been restarted successfully"