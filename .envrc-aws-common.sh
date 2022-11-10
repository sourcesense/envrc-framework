#!/usr/bin/env bash

if [ -z "${local_SNAPSHOT}" ]; then
    # shellcheck disable=SC2148 source=/.envrc-clusters.sh
    source_url "https://raw.githubusercontent.com/EcoMind/envrc-framework/v0.17.8/.envrc-clusters.sh" "sha256-DUiMd1DxtWuya_GaLXCEOYnHThhc4CNjYV8YSle4tSo="
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

use_cp aws

pre_work_on_cluster()
{
    export POD_OVERRIDES=''
}

test_vpn()
{
    log "No check on VPN"
}

set_region()
{
    local resource_region="$1"
    export RESOURCE_REGION="$resource_region"
}

set_aws_account_id()
{
    local aws_account_id="$1"
    export AWS_ACCOUNT_ID="$aws_account_id"
}

set_cluster_name()
{
    local cluster_name="$1"
    export CLUSTER_NAME="$cluster_name"
}

set_aws_profile()
{
    export AWS_PROFILE="$CLUSTER_NAME-$CLUSTER_REGION-$AWS_ACCOUNT_ID"
}

get_credentials()
{
    clusterName="${CLUSTER_NAME?Must specify cluster name in CLUSTER_NAME}"
    clusterRegion="${CLUSTER_REGION?Must specify cluster region in CLUSTER_REGION}"
    kubeConfig="${KUBECONFIG?Must specify kube config in KUBECONFIG}"

    log "Putting credentials for cluster $(ab "${clusterName}") in kubeconfig file $(ab "${kubeConfig/$HOME/\~}"), it could take a while, please be patient and ignore direnv warnings..."
    KUBECONFIG=$kubeConfig aws eks update-kubeconfig --region "${clusterRegion}" --name "${clusterName}" 2>/dev/null

    if [ -s "${kubeConfig}" ]; then
        log "Successfully got credentials from AWS and created kubeconfig: $(ab "${kubeConfig/$HOME/\~}")"
    else
        whine "Couldn't get credentials from AWS, please retry. Aborting"
    fi
}

setup_kubeconfig()
{
    KUBECONFIG=~/.kube/profiles/aws-"${AWS_SSO_ID:-$AWS_ACCOUNT_ID}"-"${CLUSTER_NAME}"

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
