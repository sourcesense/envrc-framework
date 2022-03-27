#!/usr/bin/env bash

# shellcheck source=/_bootstrap.sh
source_url "https://raw.githubusercontent.com/EcoMind/envrc-framework/v0.16.4/_bootstrap.sh" "sha256-0WaxJS+twk_d8GrA18ihI_0Y2mdX3djaxzKxI3uNaGg="

req_ver k9s 0.25.18
req_ver kustomize 4.5.2
req_ver sops 3.7.1

work_on() {
    local release_name="$1"
    local namespace_name="${2:-${release_name}}"
    export NAMESPACE="$namespace_name"
    export RELEASE_NAME="$release_name"

    prepare_and_check_k8s_context "$namespace_name"

    BASE_RELEASE="$(pwd)"
    export BASE_RELEASE

    enable_scripts
}
