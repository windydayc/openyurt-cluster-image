#!/bin/bash

sed -i 's/--controllers=.*$/--controllers=-nodelifecycle,*,bootstrapsigner,tokencleaner/g' /etc/kubernetes/manifests/kube-controller-manager.yaml

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
cmd="kubectl get pod kube-controller-manager-${master_node_name} -n kube-system -o=jsonpath={.status.phase}"

echo "Waiting for kube-controller-manager to restart..."
wait_condition_ready "$cmd" "Running" 300

if [[ $? != 0 ]]
then
    echo "timed out waiting for the kube-controller-manager to restart"
    exit 1
fi

echo "Kube-controller-manager has been restarted successfully"