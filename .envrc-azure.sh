#!/usr/bin/env bash

# shellcheck disable=SC2148 source=/.envrc-clusters.sh
source_url "https://raw.githubusercontent.com/EcoMind/envrc-framework/v0.16.3/.envrc-clusters.sh" "sha256-D5JIAUtzbeYCHPhj2Ohk1QJVEQy+cU2hYFCkIsDJINg="

if type direnv >/dev/null 2>&1; then
    # shellcheck disable=SC1091
    . <(direnv stdlib)
else
    echo "Could not load direnv stdlib" >&2
    exit 1
fi

use_cp azure

set_tenant()
{
    local tenant_id="$1"
    export TENANT_ID="$tenant_id"
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
set_group()
{
    local resource_group="$1"
    export RESOURCE_GROUP="$resource_group"
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

set_vpn_cidr()
{
    local subscription="$1"
    local group="$2"
    local gateway="$3"

    log "Getting Network CIDR from vpn gateway"
    VPN_CIDR=$(az network vnet-gateway show --subscription "$subscription" --resource-group "$group" --name "$gateway" 2>/dev/null | jq -r '.vpnClientConfiguration.vpnClientAddressPool.addressPrefixes[]' | cut -d\. -f1-3)

    if [[ ! ${VPN_CIDR} =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        whine "Couldn't get Azure Gateway Network CIDR. Aborting"
    else
        log "Successfully got Azure Gateway Network CIDR: $(ab "${VPN_CIDR}.0")"
        export VPN_CIDR
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

get_credentials()
{
    log "Putting credentials for cluster $(ab "$CLUSTER_NAME") in kubeconfig file $(ab "${KUBECONFIG/$HOME/\~}")"
    az aks get-credentials --subscription "$SUBSCRIPTION_ID" --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --file - >"$KUBECONFIG" 2>/dev/null

    if [ -s "$KUBECONFIG" ]; then
        log "Successfully got credentials from Azure and created kubeconfig: $(ab "${KUBECONFIG/$HOME/\~}")"
    else
        whine "Couldn't get credentials from Azure, please retry. Aborting"
    fi
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

# work_on_cluster() {
#     enable_scripts
#     #pre_work_on_cluster
#     log "Working on cluster: $(ab "$CLUSTER_NAME"), resource group: $(ab "$RESOURCE_GROUP"), region: $(ab "$CLUSTER_REGION")"
# }

# pre_work_on_cluster() {
#     export POD_OVERRIDES='
#     {
#         "apiVersion": "v1",
#         "kind": "Pod",
#         "spec": {
#             "tolerations": [
#                 {
#                     "effect": "NoSchedule",
#                     "key": "kubernetes.azure.com/scalesetpriority",
#                     "operator": "Equal",
#                     "value": "spot"
#                 }
#             ]
#         }
#     }'
# }
