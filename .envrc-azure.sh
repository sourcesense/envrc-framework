#!/usr/bin/env bash

# shellcheck disable=SC2148 source=/.envrc-clusters.sh
source_url "https://raw.githubusercontent.com/EcoMind/envrc-framework/v0.1.0/.envrc-clusters.sh" "sha256-dpVuvtUz1m8rGSvZt6etpLHPRRGgLaVMAW2pnTasqis="

if type direnv >/dev/null 2>&1 ; then
    # shellcheck disable=SC1090
    . <(direnv stdlib)
else
    echo "Could not load direnv stdlib" >&2
    exit 1
fi

req_no_ver az

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

test_azure_vpn() {
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

get_credentials() {
    clusterName="${CLUSTER_NAME?Must specify cluster name in CLUSTER_NAME}"
    resourceGroup="${RESOURCE_GROUP?Must specify resource group in RESOURCE_GROUP}"
    kubeConfig="${KUBECONFIG?Must specify kube config in KUBECONFIG}"

    log "Putting credentials for cluster $(b "$clusterName") in kubeconfig file $(b "$kubeConfig")"
    az aks get-credentials --resource-group "$resourceGroup" --name "$clusterName" --admin --file - >"$kubeConfig"
}

set_network_cidr() {
    local resource_group=$1
    export NETWORK_CIDR=$(az network vnet-gateway show --resource-group $resource_group --name $resource_group-gateway|jq -r '.vpnClientConfiguration.vpnClientAddressPool.addressPrefixes[]'|cut -d\. -f1-3)
}

check_azure_login() {
    az group list >/dev/null 2>&1
    if [ "$?" != 0 ]; then
        az login
    fi
}

setup_vpn() {
    VPN="$RESOURCE_GROUP-vnet"
    if  [ -z "${NETWORK_CIDR}" ]; then
        set_network_cidr "$RESOURCE_GROUP"
    fi
    test_azure_vpn "${NETWORK_CIDR}" "$VPN"
}

setup_kubeconfig() {
    KUBECONFIG=~/.kube/profiles/"$RESOURCE_GROUP"

    if [ ! -f "$KUBECONFIG" ]; then
        get_credentials
        chmod go-r $KUBECONFIG
    fi

    if [ ! -z "$NAMESPACE" ]; then
        namespaceKubeconfig=$KUBECONFIG-$NAMESPACE
        if [ ! -f "$namespaceKubeconfig" ]; then
            yq e ".contexts[].context.namespace=\"$NAMESPACE\"" "$KUBECONFIG" > $namespaceKubeconfig
            chmod go-r $namespaceKubeconfig
        fi
        KUBECONFIG=$namespaceKubeconfig
    fi

    export KUBECONFIG
}

setup_cluster_azure() {
    RESOURCE_GROUP="e4t-$ENV_NAME_TAG"
    CLUSTER_NAME="$RESOURCE_GROUP-cluster"
    check_azure_login
    setup_vpn
    work_on_cluster
    set_group "$RESOURCE_GROUP"
    set_cluster_name "$CLUSTER_NAME"
    set_location "$CLUSTER_REGION"
    setup_kubeconfig
}
