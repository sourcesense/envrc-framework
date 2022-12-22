#!/usr/bin/env bash

if [ -z "${local_SNAPSHOT}" ]; then
    # shellcheck source=/_bootstrap.sh
    source_url "https://raw.githubusercontent.com/EcoMind/envrc-framework/v0.17.10/_bootstrap.sh" "sha256-XAHXXpKkjAzEUD74eHAyKn5TArB2+FJAjoSfytebSKk="
else
    # shellcheck disable=SC1091 source="${local_SNAPSHOT}"/_bootstrap.sh
    source "${local_SNAPSHOT}"/_bootstrap.sh
fi

req_ver k9s 0.26.7
req_ver kustomize 4.5.7
req_ver sops 3.7.3

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
