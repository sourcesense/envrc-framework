#!/usr/bin/env bash

# shellcheck disable=SC2148 source=/.envrc-k8s.sh
source_url "https://raw.githubusercontent.com/EcoMind/envrc-framework/v0.11.0/.envrc-k8s.sh" "sha256-qAUT1VasvOQZh1a_Dokm+oHF+SY+ahCGaqqzZjkn1_c="

use_cp() {
    local cloud_provider="$1"
    log "Setting env for cloud provider: $(green "$(b "$cloud_provider")")"
    dep include EcoMind/k8s-common kube-config-"$cloud_provider"
}

enable_scripts() {
    BASE_CLUSTER="$(pwd)"
    export BASE_CLUSTER
    export BASE="${BASE:=$(dirname "$(find_up .envrc-k8s.sh)")}"
    export SCRIPT_BASE="${SCRIPT_BASE:=$BASE/scripts}"
    PATH_add "$SCRIPT_BASE"
}

pre_work_on_cluster() {
    # Nothing to to (depends on cloud provider)
    return 0
}

work_on_cluster() {
    enable_scripts
    pre_work_on_cluster
    log "Working on cluster: $(green "$(b "$CLUSTER_NAME")"), resource group: $(green "$(b "$RESOURCE_GROUP")"), region: $(green "$(b "$CLUSTER_REGION")")"
}
