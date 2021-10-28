#!/usr/bin/env bash

# shellcheck disable=SC2148 source=/.envrc-clusters.sh
source_url "https://raw.githubusercontent.com/EcoMind/envrc-framework/v0.1.0/.envrc-clusters.sh" "sha256-dpVuvtUz1m8rGSvZt6etpLHPRRGgLaVMAW2pnTasqis="

use_cp azure

prepare_eye4task_aks() {
    local kube_config="${1}"
    set_azure_profile "unknown"
    set_kubeconfig_profile "e4t-azure-${kube_config}"
}
