#!/usr/bin/env bash

if [ -z "${local_SNAPSHOT}" ]; then
    # shellcheck disable=SC2148 source=/.envrc-clusters.sh
    source_url "https://raw.githubusercontent.com/EcoMind/envrc-framework/v0.18.0/.envrc-clusters.sh" "sha256-eWAfYyRZ66c9gWKgM+HGT434k7NgWQk4xzP3Etu9lO0="
else
    # shellcheck disable=SC1091 source="${local_SNAPSHOT}"/.envrc-clusters.sh
    source "${local_SNAPSHOT}"/.envrc-clusters.sh
fi

work_on_cluster()
{
    pre_work_on_cluster
    log "Working on cluster: $(ab "$CLUSTER_NAME"), project id: $(ab "$PROJECT_ID"), region: $(ab "$CLUSTER_REGION")"
}

if type direnv >/dev/null 2>&1; then
    # shellcheck disable=SC1091
    . <(direnv stdlib)
else
    echo "Could not load direnv stdlib" >&2
    exit 1
fi

use_cp gcp

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

set_project_id()
{
    local project_id="$1"
    export PROJECT_ID="$project_id"
}

set_cluster_name()
{
    local cluster_name="$1"
    export CLUSTER_NAME="$cluster_name"
}

get_credentials()
{
    clusterName="${CLUSTER_NAME?Must specify cluster name in CLUSTER_NAME}"
    projectId="${PROJECT_ID?Must specify project id in PROJECT_ID}"
    clusterRegion="${CLUSTER_REGION?Must specify cluster region in CLUSTER_REGION}"
    kubeConfig="${KUBECONFIG?Must specify kube config in KUBECONFIG}"

    log "Putting credentials for cluster $(ab "${clusterName}") in kubeconfig file $(ab "${kubeConfig/$HOME/\~}"), it could take a while, please be patient and ignore direnv warnings..."
    KUBECONFIG=$kubeConfig gcloud container clusters get-credentials "${clusterName}" --region "${clusterRegion}" --project "${projectId}" 2>/dev/null

    if [ -s "${kubeConfig}" ]; then
        log "Successfully got credentials from GCP and created kubeconfig: $(ab "${kubeConfig/$HOME/\~}")"
    else
        whine "Couldn't get credentials from GCP, please retry. Aborting"
    fi
}

check_gcp_login()
{
    log "Checking access to GCP Cluster $(ab "${CLUSTER_NAME}"), it could take a while, please be patient and ignore direnv warnings..."

    gcloud auth print-access-token >/dev/null 2>&1
    # shellcheck disable=SC2181
    if [ "$?" != 0 ]; then
        gcloud auth login 2>/dev/null
        if [ "$?" = 0 ]; then
            log "$(ab "Successfully logged in to GCP with user $(gcloud config get-value account)")"

            gcloud auth application-default print-access-token >/dev/null 2>&1
            # shellcheck disable=SC2181
            if [ "$?" != 0 ]; then
                gcloud auth application-default login 2>/dev/null
                if [ "$?" = 0 ]; then
                    log "$(ab "Successfully logged in to GCP for SOPS support with user $(gcloud config get-value account)")"
                else
                    whine "Couldn't login to GCP, please retry running a $(b "direnv reload"). Aborting"
                fi
            else
                log "Already logged in to GCP with user $(ab "$(gcloud config get-value account)")"
            fi
        else
            whine "Couldn't login to GCP, please retry running a $(b "direnv reload"). Aborting"
        fi
    else
        log "Already logged in to GCP with user $(ab "$(gcloud config get-value account)")"
    fi
}

setup_kubeconfig()
{
    parentDir="$HOME/.kube/profiles/gcp"
    mkdir -p "$parentDir"
    KUBECONFIG="$parentDir/${PROJECT_ID}-${CLUSTER_NAME}"

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
        export KUBECONFIG
        status=$(kubectl version -o json 2>/dev/null | jq -r ".serverVersion.gitVersion")
        [ "$status" = "null" ] && whine "Cannot connect to cluster $(ab "${CLUSTER_NAME}"). Try remove your kubeconfig file $(ab "${KUBECONFIG/$HOME/\~}")"
    fi
}

setup_cluster_gcp()
{
    set_project_id "${PROJECT_ID}"
    set_region "${CLUSTER_REGION}"
    CLUSTER_NAME="${CLUSTER_NAME:-${PROJECT_ID}-cluster}"
    set_cluster_name "${CLUSTER_NAME}"
    check_gcp_login
    setup_kubeconfig
    work_on_cluster
}
