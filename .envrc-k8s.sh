#!/usr/bin/env bash

# shellcheck source=/_bootstrap.sh
source_url "https://raw.githubusercontent.com/EcoMind/envrc-framework/v0.17.5/_bootstrap.sh" "sha256-N9YLoWLUaiR2wfgtvsC1v1taoYKfML+8n2_+zfCfiRg="

req_ver k9s 0.25.21
req_ver kustomize 4.5.5
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
