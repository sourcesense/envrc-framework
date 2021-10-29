#!/usr/bin/env bash

# shellcheck source=/scripts/_azure-bootstrap.sh
source_url "https://raw.githubusercontent.com/EcoMind/envrc-framework/v0.3.0/_azure-bootstrap.sh" "sha256-+MsSRutiQ+1Vzm8cB864vfR0GTSLYOQa969z4NMNM94="

clusterName="${CLUSTER_NAME?Must specify cluster name in CLUSTER_NAME}"
resourceGroup="${RESOURCE_GROUP?Must specify resource group in RESOURCE_GROUP}"
kubeConfig="${KUBECONFIG?Must specify kube config in KUBECONFIG}"

log "Putting credentials for cluster $(b "$clusterName") in kubeconfig file $(b "$kubeConfig")"
az aks get-credentials --resource-group "$resourceGroup" --name "$clusterName" --admin --file - >"$kubeConfig"
