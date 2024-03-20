#!/usr/bin/env bash

if [ -z "${local_SNAPSHOT}" ]; then
    # shellcheck disable=SC2148 source=/.envrc-aws-common.sh
    source_url "https://raw.githubusercontent.com/sourcesense/envrc-framework/v0.19.1/.envrc-aws-common.sh" "sha256-5GFLFYyKcLf6Ku9zFeQSNWbCg85YkkTBQicHaZHGWKg="
else
    # shellcheck disable=SC1091 source="${local_SNAPSHOT}"/.envrc-aws-common.sh
    source "${local_SNAPSHOT}"/.envrc-aws-common.sh
fi

work_on_cluster()
{
    pre_work_on_cluster
    log "Working on cluster: $(ab "$CLUSTER_NAME"), AWS Account id: $(ab "$AWS_ACCOUNT_ID"), region: $(ab "$CLUSTER_REGION")"
}

check_aws_login()
{
    log "Checking access to AWS Cluster $(ab "${CLUSTER_NAME}"), it could take a while, please be patient and ignore direnv warnings..."

    aws sts get-caller-identity >/dev/null 2>&1
    # shellcheck disable=SC2181
    if [ "$?" != 0 ]; then
        whine "Couldn't login to AWS, please check your credentials (see $(ab "~/.aws/credentials")), then run $(b "direnv reload"). Aborting"
    else
        log "Already logged in to AWS with user $(ab "$(aws sts get-caller-identity | jq -r .Arn -)")"
    fi
}

setup_cluster_aws()
{
    set_aws_account_id "${AWS_ACCOUNT_ID}"
    set_region "${CLUSTER_REGION}"

    set_cluster_name "${CLUSTER_NAME?Must specify cluster name in CLUSTER_NAME}"

    log "Using AWS Profile $(ab "$AWS_PROFILE")"
    set_aws_profile
    check_aws_login
    setup_kubeconfig
    work_on_cluster
}
