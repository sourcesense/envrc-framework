#!/usr/bin/env bash

if [ -z "${local_SNAPSHOT}" ]; then
    # shellcheck disable=SC2148 source=/.envrc-aws-sso-access.sh
    source_url "https://raw.githubusercontent.com/EcoMind/envrc-framework/v0.18.5/.envrc-aws-sso-access.sh" "sha256-Dwj1769JwfMzCK1C3uwFl2DdVPDQnG8aogzLzw6Rba8="
    # shellcheck disable=SC2148 source=/.envrc-aws-common.sh
    source_url "https://raw.githubusercontent.com/EcoMind/envrc-framework/v0.18.5/.envrc-aws-common.sh" "sha256-ytA3JwDAllP2yw7EQBSGKFtO1kxAf0POiYKU2KgcEx4="
else
    # shellcheck disable=SC1091 source="${local_SNAPSHOT}"/.envrc-aws-sso-access.sh
    source "${local_SNAPSHOT}"/.envrc-aws-sso-access.sh
    # shellcheck disable=SC1091 source="${local_SNAPSHOT}"/.envrc-aws-common.sh
    source "${local_SNAPSHOT}"/.envrc-aws-common.sh
fi

work_on_cluster()
{
    pre_work_on_cluster
    log "Working on cluster: $(ab "$CLUSTER_NAME"), AWS SSO id: $(ab "$AWS_SSO_ID"), region: $(ab "$CLUSTER_REGION")"
}

setup_cluster_aws_sso()
{
    set_aws_sso_id "${AWS_SSO_ID}"
    set_aws_sso_role_name "${AWS_SSO_ROLE_NAME}"
    set_aws_account_id "${AWS_ACCOUNT_ID}"
    set_aws_sso_region "${AWS_SSO_REGION}"
    set_region "${CLUSTER_REGION}"

    set_cluster_name "${CLUSTER_NAME?Must specify cluster name in CLUSTER_NAME}"

    set_aws_profile
    check_aws_login_sso
    setup_kubeconfig
    work_on_cluster
}
