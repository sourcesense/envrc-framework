#!/usr/bin/env bash

# shellcheck disable=SC2148 source=/.envrc-clusters.sh
source_url "https://raw.githubusercontent.com/EcoMind/envrc-framework/v0.10.0/.envrc-clusters.sh" "sha256-vRo61rDMLGVl6XauULiO+jF4BpbSonU7KUtfAx3RwCg="

if type direnv >/dev/null 2>&1 ; then
    # shellcheck disable=SC1091
    . <(direnv stdlib)
else
    echo "Could not load direnv stdlib" >&2
    exit 1
fi

req_no_ver az

use_cp azure

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
    local net="$1"
    local vpn="$2"
    
    ifconfig | grep "$net" 2>/dev/null 1>/dev/null
    # shellcheck disable=SC2181
    if [ "$?" = 0 ] ; then
        log "VPN Connection $(green "$(b "$vpn") already established, going on.")"
    else
        log "VPN Network not found, establishing VPN connection $(green "$(b "$vpn")")"
        scutil --nc start "$vpn"
    fi

    local connection
    local attempts=0
    local maxAttempts=10
    while [ -z "$connection" ] && (( attempts < maxAttempts ))
    do
        connection="$(scutil --nc status "$vpn"|head -1|grep "^Connected$")"
        attempts=$(( attempts + 1 ))
        if [ -z "$connection" ]; then
            sleep 1
        fi
    done
    log "VPN Connection: $(green "$(b "$connection")")"
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

    log "Putting credentials for cluster $(green "$(b "${clusterName}")") in kubeconfig file $(green "$(b "${kubeConfig/$HOME/\~}")"), it could take a while, please be patient and ignore direnv warnings..."
    az aks get-credentials --resource-group "${resourceGroup}" --name "${clusterName}" --admin --file - > "${kubeConfig}" 2>/dev/null

    if [ -s "${kubeConfig}" ]; then
        log "Successfully got credentials from Azure and created kubeconfig: $(green "$(b "${kubeConfig/$HOME/\~}")")"
    else
        whine "Couldn't get credentials from Azure, please retry. Aborting"
    fi
}

set_network_cidr() {
    local resource_group="$1"
    log "Getting Network CIDR from $(green "$(b "${resource_group}")"), it could take a while, please be patient and ignore direnv warnings..."
    NETWORK_CIDR=$(az network vnet-gateway show --resource-group "${resource_group}" --name "${resource_group}-gateway" 2>/dev/null | jq -r '.vpnClientConfiguration.vpnClientAddressPool.addressPrefixes[]'|cut -d\. -f1-3)

    if [[ ! ${NETWORK_CIDR} =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        whine "Couldn't get Azure Gateway Network CIDR. Aborting"
    else
        log "Successfully got Azure Gateway Network CIDR: $(green "$(b "${NETWORK_CIDR}.0")")"
        export NETWORK_CIDR
    fi
}

check_azure_login() {
    log "Checking access to Azure Cluster $(green "$(b "${CLUSTER_NAME}")"), it could take a while, please be patient and ignore direnv warnings..."

    az group list >/dev/null 2>&1
    # shellcheck disable=SC2181
    if [ "$?" != 0 ]; then
        if [ "$(az login 2>/dev/null | jq)" ]; then
            log "$(green "$(b "Successfully logged in to Azure")")"
        else
            whine "Couldn't login to Azure, please retry. Aborting"
        fi
    fi
}

setup_vpn() {
    local vpn="${RESOURCE_GROUP}-vnet"
    if  [ -z "${NETWORK_CIDR}" ]; then
        set_network_cidr "${RESOURCE_GROUP}"
    fi
    test_azure_vpn "${NETWORK_CIDR}" "${vpn}"
}

setup_kubeconfig() {
    KUBECONFIG=~/.kube/profiles/"${RESOURCE_GROUP}"

    if [ ! -s "${KUBECONFIG}" ]; then
        get_credentials
        chmod go-r "${KUBECONFIG}"
    fi
    if [ -n "${NAMESPACE}" ]; then
        namespaceKubeconfig="${KUBECONFIG}-${NAMESPACE}"
        if [ ! -f "${namespaceKubeconfig}" ]; then
            yq e ".contexts[].context.namespace=\"${NAMESPACE}\"" "${KUBECONFIG}" > "${namespaceKubeconfig}"
            chmod go-r "${namespaceKubeconfig}"
            log "Successfully created env specific kubeconfig: $(green "$(b "${namespaceKubeconfig/$HOME/\~}")")"
        fi
        KUBECONFIG="${namespaceKubeconfig}"
    fi
    export KUBECONFIG
}

setup_cluster_azure() {
    CLUSTER_NAME="${RESOURCE_GROUP}-cluster"
    check_azure_login
    setup_vpn
    work_on_cluster
    set_group "${RESOURCE_GROUP}"
    set_cluster_name "${CLUSTER_NAME}"
    set_location "${CLUSTER_REGION}"
    setup_kubeconfig
}
