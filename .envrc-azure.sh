#!/usr/bin/env bash

# shellcheck disable=SC2148 source=/.envrc-clusters.sh
source_url "https://raw.githubusercontent.com/EcoMind/envrc-framework/v0.1.0/.envrc-clusters.sh" "sha256-dpVuvtUz1m8rGSvZt6etpLHPRRGgLaVMAW2pnTasqis="

use_cp azure

prepare_eye4task_aks() {
    local kube_config="${1}"
    set_azure_profile "unknown"
    set_kubeconfig_profile "e4t-azure-${kube_config}"
}

pre_work_on_cluster() {
    export POD_OVERRIDES='
    {
        "apiVersion": "v1",
        "kind": "Pod",
        "spec": {
            "tolerations": [
                {
                    "effect": "NoSchedule",
                    "key": "kubernetes.azure.com/scalesetpriority",
                    "operator": "Equal",
                    "value": "spot"
                }
            ]
        }
    }'
}

test-azure-vpn() {
    local NET="$1"
    local VPN="$2"
    ifconfig | grep $NET 2>/dev/null 1>/dev/null
    if [ "$?" = 0 ]
    then
        echo "VPN Connection $(b "$VPN") already established, going on."
    else
        echo "VPN Network not found, starting up connection $(b "$VPN")"
        scutil --nc start "$VPN"
    fi

    local connection
    local attempts=0
    local maxAttempts=10
    while [ -z "$connection" ] && (( attempts < maxAttempts ))
    do
        connection="$(scutil --nc status "$VPN"|head -1|grep "^Connected$")"
        attempts=$(( attempts + 1 ))
        if [ -z "$connection" ]; then
            sleep 1
        fi
    done
    echo "VPN Connection: $(b "$connection")"
}

set_group() {
    local resource_group="$1"
    export RESOURCE_GROUP="$resource_group"
}

set_location() {
    local resource_location="$1"
    export RESOURCE_LOCATION="$resource_location"
}

set_subscription() {
    local subscription_id="$1"
    export SUBSCRIPTION_ID="$subscription_id"
}

set_tenant() {
    local tenant_id="$1"
    export TENANT_ID="$tenant_id"
}

set_cluster_name() {
    local cluster_name="$1"
    export CLUSTER_NAME="$cluster_name"
}



