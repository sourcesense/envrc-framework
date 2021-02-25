#!/usr/bin/env bash

# shellcheck source=/_bootstrap.sh
source_url "https://raw.githubusercontent.com/EcoMind/envrc-framework/main/_bootstrap.sh" "sha256-CUMUkFdcUU9RtKb4FX5xc++eIqNgINTeNrsiHzQ8q7Q="

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
