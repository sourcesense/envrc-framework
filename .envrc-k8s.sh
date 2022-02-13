#!/usr/bin/env bash

# shellcheck source=/_bootstrap.sh
source_url "https://raw.githubusercontent.com/EcoMind/envrc-framework/v0.13.0/_bootstrap.sh" "sha256-qpOSVsGlC2OtCrx27k+E8EfyRjxGgA1L4_f3Pwxh4ik="

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
