#!/usr/bin/env bash

if [ -z "${local_SNAPSHOT}" ]; then
    # shellcheck disable=SC2148 source=/.envrc-clusters.sh
    source_url "https://raw.githubusercontent.com/EcoMind/envrc-framework/v0.17.10/.envrc-clusters.sh" "sha256-Mz4HW6BOQzZc5+RWWzoV0ceRrLr5oFVSIPES3Oy7Ei0="
else
    # shellcheck disable=SC1091 source="${local_SNAPSHOT}"/.envrc-clusters.sh
    source "${local_SNAPSHOT}"/.envrc-clusters.sh
fi

if type direnv >/dev/null 2>&1; then
    # shellcheck disable=SC1091
    . <(direnv stdlib)
else
    echo "Could not load direnv stdlib" >&2
    exit 1
fi

use_cp azure

work_on_cluster()
{
    enable_scripts
    pre_work_on_cluster
    log "Working on cluster: $(ab "$CLUSTER_NAME"), resource group: $(ab "$RESOURCE_GROUP"), resource location: $(ab "$RESOURCE_LOCATION")"
}

pre_work_on_cluster()
{
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

test_azure_vpn()
{
    ifconfig | grep "$VPN_CIDR" 2>/dev/null 1>/dev/null
    # shellcheck disable=SC2181
    if [ "$?" = 0 ]; then
        log "VPN Connection $(a "$(b "$vpn_name") already established, going on.")"
    else
        log "VPN Network not found, establishing VPN connection $(ab "$vpn_name")"
        scutil --nc start "$vpn_name"
    fi

    local connection
    local attempts=0
    local maxAttempts=10
    while [ -z "$connection" ] && ((attempts < maxAttempts)); do
        connection="$(scutil --nc status "$vpn_name" | head -1 | grep "^Connected$")"
        attempts=$((attempts + 1))
        if [ -z "$connection" ]; then
            sleep 1
        fi
    done
    log "VPN Connection: $(ab "$connection")"
}

set_group()
{
    local resource_group="$1"
    export RESOURCE_GROUP="$resource_group"
}

set_location()
{
    local resource_location="$1"
    export RESOURCE_LOCATION="$resource_location"
}

set_subscription()
{
    local subscription_id="$1"
    export SUBSCRIPTION_ID="$subscription_id"
}

set_tenant()
{
    local tenant_id="$1"
    export TENANT_ID="$tenant_id"
}

set_vpn_gateway_name()
{
    local vpn_gateway_name="$1"
    export VPN_GATEWAY_NAME="$vpn_gateway_name"
}

set_cluster_name()
{
    local cluster_name="$1"
    export CLUSTER_NAME="$cluster_name"
}

get_credentials()
{
    clusterName="${CLUSTER_NAME?Must specify cluster name in CLUSTER_NAME}"
    resourceGroup="${RESOURCE_GROUP?Must specify resource group in RESOURCE_GROUP}"
    kubeConfig="${KUBECONFIG?Must specify kube config in KUBECONFIG}"
    subscriptionId="${SUBSCRIPTION_ID?Must specify kube config in SUBSCRIPTION_ID}"

    log "Putting credentials for cluster $(ab "${clusterName}") in kubeconfig file $(ab "${kubeConfig/$HOME/\~}"), it could take a while, please be patient and ignore direnv warnings..."
    # az aks get-credentials --subscription "${subscriptionId}" --resource-group "${resourceGroup}" --name "${clusterName}" --admin --file - >"${kubeConfig}" 2>/dev/null
    az aks get-credentials --subscription "${subscriptionId}" --resource-group "${resourceGroup}" --name "${clusterName}" --file - >"${kubeConfig}" 2>/dev/null

    if [ -s "${kubeConfig}" ]; then
        log "Successfully got credentials from Azure and created kubeconfig: $(ab "${kubeConfig/$HOME/\~}")"
    else
        whine "Couldn't get credentials from Azure, please retry. Aborting"
    fi
}

set_vpn_cidr()
{
    local subscription="$1"
    local group="$2"
    local gateway="$3"

    local cache_dir
    cache_dir="$(cache_dir_of "azure/$subscription/$group")"
    local cache_file="$cache_dir/vnet-gateway_${gateway}_cidr"
    if [ -s "$cache_file" ]; then
        log "Getting Network CIDR from cache file: $(tildify "$cache_file"))"
        VPN_CIDR="$(cat "$cache_file")"
    else
        log "Getting Network CIDR from vpn gateway"
        VPN_CIDR=$(az network vnet-gateway show --subscription "$subscription" --resource-group "$group" --name "$gateway" 2>/dev/null | jq -r '.vpnClientConfiguration.vpnClientAddressPool.addressPrefixes[]' | cut -d\. -f1-3)
        log "Storing Network CIDR in cache file: $cache_file"
        echo "$VPN_CIDR" >"$cache_file"
    fi

    if [[ ! ${VPN_CIDR} =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        whine "Couldn't get Azure Gateway Network CIDR. Aborting"
    else
        log "Successfully got Azure Gateway Network CIDR: $(ab "${VPN_CIDR}.0")"
        export VPN_CIDR
    fi
}

check_azure_login()
{
    log "Checking access to Azure"

    az group list >/dev/null 2>&1
    # shellcheck disable=SC2181
    if [ "$?" != 0 ]; then
        if [ "$(az login 2>/dev/null | jq)" ]; then
            log "$(ab "Successfully logged in to Azure")"
        else
            whine "Couldn't login to Azure, please retry. Aborting"
        fi
    fi
}

setup_vpn()
{
    local subscription="$1"
    local group="$2"
    local gateway="$3"
    local vpn_name="$4"

    if [ -z "${VPN_CIDR}" ]; then
        set_vpn_cidr "$subscription" "$group" "$gateway"
    fi

    test_azure_vpn
}

setup_kubeconfig()
{
    subscriptionName=$(az account subscription show --subscription-id "$SUBSCRIPTION_ID" 2>/dev/null | jq -r '.displayName')
    parentDir="$HOME/.kube/profiles/azure"
    mkdir -p "$parentDir"
    KUBECONFIG="$parentDir/$subscriptionName-$CLUSTER_NAME"

    if [ ! -s "${KUBECONFIG}" ]; then
        get_credentials
        chmod go-r "${KUBECONFIG}"
    fi
    if [ -n "${NAMESPACE}" ]; then
        namespaceKubeconfig="${KUBECONFIG}-${NAMESPACE}"
        if [ ! -f "${namespaceKubeconfig}" ]; then
            yq e ".contexts[].context.namespace=\"${NAMESPACE}\"" "${KUBECONFIG}" >"${namespaceKubeconfig}"
            chmod go-r "${namespaceKubeconfig}"
            log "Successfully created env specific kubeconfig: $(ab "${namespaceKubeconfig/$HOME/\~}")"
        fi
        KUBECONFIG="${namespaceKubeconfig}"
    fi
    export KUBECONFIG
}

setup_cluster_azure()
{
    work_on_cluster
    setup_kubeconfig
}
