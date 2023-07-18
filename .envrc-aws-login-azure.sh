#!/usr/bin/env bash

if [ -z "${local_SNAPSHOT}" ]; then
    # shellcheck disable=SC2148 source=/.envrc-aws-common.sh
    source_url "https://raw.githubusercontent.com/EcoMind/envrc-framework/v0.18.4/.envrc-aws-common.sh" "sha256-hDRrRy3uZXpG7WqL13f1ptFqjf_pi6kaR2ModSVY_Vc="
else
    # shellcheck disable=SC1091 source="${local_SNAPSHOT}"/.envrc-aws-common.sh
    source "${local_SNAPSHOT}"/.envrc-aws-common.sh
fi

work_on_cluster()
{
    pre_work_on_cluster
    log "Working on cluster: $(ab "$CLUSTER_NAME"), AWS Account id: $(ab "$AWS_ACCOUNT_ID"), region: $(ab "$CLUSTER_REGION")"
}

req_ver kubelogin 0.0.30

kubeconfigTemplate="apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: \${CERTIFICATE_AUTHORITY_DATA}
    server: https://\${EKS_SERVER_PREFIX}.\${CLUSTER_REGION}.eks.amazonaws.com
  name: arn:aws:eks:\${CLUSTER_REGION}:\${AWS_ACCOUNT_ID}:cluster/\${CLUSTER_NAME}
contexts:
- context:
    cluster: arn:aws:eks:\${CLUSTER_REGION}:\${AWS_ACCOUNT_ID}:cluster/\${CLUSTER_NAME}
    user: azure-user-sample
  name: arn:aws:eks:\${CLUSTER_REGION}:\${AWS_ACCOUNT_ID}:cluster/\${CLUSTER_NAME}
current-context: arn:aws:eks:\${CLUSTER_REGION}:\${AWS_ACCOUNT_ID}:cluster/\${CLUSTER_NAME}
kind: Config
preferences: {}
users:
- name: azure-user-sample
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      args:
      - get-token
      - --environment
      - AzurePublicCloud
      - --server-id
      - \${AZURE_CLIENT_ID}
      - --client-id
      - \${AZURE_CLIENT_ID}
      - --tenant-id
      - \${AZURE_TENANT_ID}
      command: kubelogin
      env: null
      provideClusterInfo: false
"

set_azure_client_id()
{
    local azure_client_id="$1"
    export AZURE_CLIENT_ID="$azure_client_id"
}

set_azure_tenant_id()
{
    local azure_tenant_id="$1"
    export AZURE_TENANT_ID="$azure_tenant_id"
}

set_eks_server_prefix()
{
    local eks_server_prefix="$1"
    export EKS_SERVER_PREFIX="$eks_server_prefix"
}

set_certificate_authority_data()
{
    local certificate_authority_data="$1"
    export CERTIFICATE_AUTHORITY_DATA="$certificate_authority_data"
}

get_credentials()
{
    echo "$kubeconfigTemplate" | envsubst >"$KUBECONFIG"
}

ensure_logged_in()
{
    # In non-interactive mode, we don't see a login prompt, so we need to
    # explicitly check if we're logged in.
    log "Checking if logged in to Azure, please follow on-screen prompts if any"
    if kubelogin get-token --environment AzurePublicCloud --server-id "$AZURE_CLIENT_ID" --client-id "$AZURE_CLIENT_ID" --tenant-id "$AZURE_TENANT_ID" >/dev/null; then
        log "Currently logged in to Azure, continuing with configuration"
    else
        whine "Not logged in to Azure, please login and try again"
    fi
}

setup_cluster_aws_login_azure()
{
    set_azure_client_id "${AZURE_CLIENT_ID?Must specify Azure client id in AZURE_CLIENT_ID}"
    set_azure_tenant_id "${AZURE_TENANT_ID?Must specify Azure tenant id in AZURE_TENANT_ID}"
    set_aws_account_id "${AWS_ACCOUNT_ID?Must specify AWS account id in AWS_ACCOUNT_ID}"
    set_eks_server_prefix "${EKS_SERVER_PREFIX?Must specify EKS API server prefix in EKS_SERVER_PREFIX}"
    set_certificate_authority_data "${CERTIFICATE_AUTHORITY_DATA?Must specify certificate authority data in CERTIFICATE_AUTHORITY_DATA}"
    set_region "${CLUSTER_REGION?Must specify cluster region in CLUSTER_REGION}"

    set_cluster_name "${CLUSTER_NAME?Must specify cluster name in CLUSTER_NAME}"

    set_aws_profile
    setup_kubeconfig
    work_on_cluster
}
