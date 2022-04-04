#!/usr/bin/env bash

# shellcheck disable=SC2148 source=/.envrc-clusters.sh
source_url "https://raw.githubusercontent.com/EcoMind/envrc-framework/v0.16.5/.envrc-clusters.sh" "sha256-a5wiANzdjgnv_H1vN+uT8VZiIrjOmU8w7J134CJUdU8="

work_on_cluster() {
    pre_work_on_cluster
    log "Working on cluster: $(ab "$CLUSTER_NAME"), AWS SSO id: $(ab "$AWS_SSO_ID"), region: $(ab "$CLUSTER_REGION")"
}

if type direnv >/dev/null 2>&1 ; then
    # shellcheck disable=SC1091
    . <(direnv stdlib)
else
    echo "Could not load direnv stdlib" >&2
    exit 1
fi

use_cp aws

pre_work_on_cluster() {
    export POD_OVERRIDES=''
}

test_vpn() {
    log "No check on VPN"
}

set_region() {
    local resource_region="$1"
    export RESOURCE_REGION="$resource_region"
}

set_aws_account_id() {
    local aws_account_id="$1"
    export AWS_ACCOUNT_ID="$aws_account_id"
}

set_aws_sso_id() {
    local aws_sso_id="$1"
    export AWS_SSO_ID="$aws_sso_id"
}

set_aws_sso_role_name() {
    local aws_sso_role_name="$1"
    export AWS_SSO_ROLE_NAME="$aws_sso_role_name"
}

set_cluster_name() {
    local cluster_name="$1"
    export CLUSTER_NAME="$cluster_name"
}

set_aws_profile() {
    export AWS_PROFILE="$CLUSTER_NAME-$CLUSTER_REGION-$AWS_ACCOUNT_ID"
}

get_credentials() {
    clusterName="${CLUSTER_NAME?Must specify cluster name in CLUSTER_NAME}"
    clusterRegion="${CLUSTER_REGION?Must specify cluster region in CLUSTER_REGION}"
    kubeConfig="${KUBECONFIG?Must specify kube config in KUBECONFIG}"

    log "Putting credentials for cluster $(ab "${clusterName}") in kubeconfig file $(ab "${kubeConfig/$HOME/\~}"), it could take a while, please be patient and ignore direnv warnings..."
    KUBECONFIG=$kubeConfig aws eks update-kubeconfig --region "${clusterRegion}" --name "${clusterName}" 2>/dev/null

    if [ -s "${kubeConfig}" ]; then
        log "Successfully got credentials from AWS and created kubeconfig: $(ab "${kubeConfig/$HOME/\~}")"
    else
        whine "Couldn't get credentials from AWS, please retry. Aborting"
    fi
}

check_aws_login_sso() {
    log "Checking access to AWS Cluster $(ab "${CLUSTER_NAME}"), it could take a while, please be patient and ignore direnv warnings..."

    awsConfig="$HOME/.aws/config"
    if grep "\[profile $AWS_PROFILE\]" "$awsConfig" >/dev/null 2>&1 ; then
        log "Found profile $(ab "${AWS_PROFILE}") in AWS config file $(ab "${awsConfig/$HOME/\~}")"
    else
        warn "Couldn't find profile $(ab "${AWS_PROFILE}") in AWS config file $(ab "${awsConfig/$HOME/\~}"), will create it now"
        log "Setting up AWS SSO credentials in order to access SSO ID $(ab "${AWS_SSO_ID}") with SSO role $(ab "${AWS_SSO_ROLE_NAME}") in region $(ab "${CLUSTER_REGION}") (account id: $(ab "${AWS_ACCOUNT_ID}"))"
        aws configure set sso_start_url "https://${AWS_SSO_ID}.awsapps.com/start"
        aws configure set sso_region "${CLUSTER_REGION}"
        aws configure set sso_account_id "${AWS_ACCOUNT_ID}"
        aws configure set sso_role_name "${AWS_SSO_ROLE_NAME}"
        aws configure set region "${CLUSTER_REGION}"
        aws configure set output json
    fi

    aws sts get-caller-identity >/dev/null 2>&1
    # shellcheck disable=SC2181
    if [ "$?" != 0 ]; then
        aws sso login 2>/dev/null
        if [ "$?" = 0 ]; then
            log "$(ab "Successfully logged in to AWS with user $(aws sts get-caller-identity | jq -r .Arn -)")"
        else
            whine "Couldn't login to AWS, please retry running a $(b "direnv reload"). Aborting"
        fi
    else
        log "Already logged in to AWS with user $(ab "$(aws sts get-caller-identity | jq -r .Arn -)")"
    fi
}

setup_kubeconfig() {
    KUBECONFIG=~/.kube/profiles/aws-"${AWS_SSO_ID}"-"${CLUSTER_NAME}"

    if [ ! -s "${KUBECONFIG}" ]; then
        get_credentials
        chmod go-r "${KUBECONFIG}"
    fi
    if [ -n "${NAMESPACE}" ]; then
        namespaceKubeconfig="${KUBECONFIG}-${NAMESPACE}"
        if [ ! -f "${namespaceKubeconfig}" ]; then
            yq e ".contexts[].context.namespace=\"${NAMESPACE}\"" "${KUBECONFIG}" > "${namespaceKubeconfig}"
            chmod go-r "${namespaceKubeconfig}"
            log "Successfully created env specific kubeconfig: $(ab "${namespaceKubeconfig/$HOME/\~}")"
        fi
        KUBECONFIG="${namespaceKubeconfig}"
    fi
    export KUBECONFIG
}

setup_cluster_aws_sso() {
    set_aws_sso_id "${AWS_SSO_ID}"
    set_aws_sso_role_name "${AWS_SSO_ROLE_NAME}"
    set_aws_account_id "${AWS_ACCOUNT_ID}"
    set_region "${CLUSTER_REGION}"

    set_cluster_name "${CLUSTER_NAME?Must specify cluster name in CLUSTER_NAME}"

    set_aws_profile
    check_aws_login_sso
    setup_kubeconfig
    work_on_cluster
}
