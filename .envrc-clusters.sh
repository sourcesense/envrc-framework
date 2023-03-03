#!/usr/bin/env bash

if [ -z "${local_SNAPSHOT}" ]; then
    # shellcheck disable=SC2148 source=/.envrc-k8s.sh
    source_url "https://raw.githubusercontent.com/EcoMind/envrc-framework/v0.17.17/.envrc-k8s.sh" "sha256-_0JHsSpa8H+9gnZMnPTcHzBtClpeyHwNdeeSXJnG1WU="
else
    # shellcheck disable=SC1091 source="${local_SNAPSHOT}"/.envrc-k8s.sh
    source "${local_SNAPSHOT}"/.envrc-k8s.sh
fi

use_cp()
{
    local cloud_provider="$1"
    log "Setting env for cloud provider: $(ab "$cloud_provider")"
    dep include EcoMind/k8s-common kube-config-"$cloud_provider"
}

enable_scripts()
{
    BASE_CLUSTER="$(pwd)"
    export BASE_CLUSTER
    export BASE="${BASE:=$(dirname "$(find_up .envrc-k8s.sh)")}"
    export SCRIPT_BASE="${SCRIPT_BASE:=$BASE/scripts}"
    PATH_add "$SCRIPT_BASE"
}

pre_work_on_cluster()
{
    # Nothing to to (depends on cloud provider)
    return 0
}

work_on_cluster()
{
    enable_scripts
    pre_work_on_cluster
    log "Working on cluster: $(ab "$CLUSTER_NAME")"
}

cache_dir_of()
{
    local subject="$1"
    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/envrc-framework/${subject}"
    if [ ! -d "${cache_dir}" ]; then
        mkdir -p "${cache_dir}"
    fi
    echo "${cache_dir}"
}
