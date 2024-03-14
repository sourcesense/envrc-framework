#!/usr/bin/env bash

if [ -z "${local_SNAPSHOT}" ]; then
    # shellcheck source=/_bootstrap.sh
    source_url "https://raw.githubusercontent.com/sourcesense/envrc-framework/v0.19.0/_bootstrap.sh" "sha256-vqfn0gJFi4YyWq53OuhQ4KV7kaml7W8M0_Q7LSy4APw="
else
    # shellcheck disable=SC1091 source="${local_SNAPSHOT}"/_bootstrap.sh
    source "${local_SNAPSHOT}"/_bootstrap.sh
fi

req_ver k9s 0.32.3
req_ver kustomize 5.3.0
req_ver sops 3.8.1

work_on()
{
    local release_name="$1"
    local namespace_name="${2:-${release_name}}"
    export NAMESPACE="$namespace_name"
    export RELEASE_NAME="$release_name"

    prepare_and_check_k8s_context "$namespace_name"

    BASE_RELEASE="$(pwd)"
    export BASE_RELEASE

    enable_scripts
}
