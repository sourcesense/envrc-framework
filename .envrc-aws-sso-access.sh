#!/usr/bin/env bash

if [ -z "${local_SNAPSHOT}" ]; then
    # shellcheck disable=SC2148 source=/.envrc-aws-common.sh
    source_url "https://raw.githubusercontent.com/EcoMind/envrc-framework/v0.18.5/_bootstrap.sh" "sha256-oYhBz1QJnTcbh7DUEuoCnRy5IZIcRPHcs1SVuFyJJjY="
else
    # shellcheck disable=SC1091 source="${local_SNAPSHOT}"/_bootstrap.sh
    source "${local_SNAPSHOT}"/_bootstrap.sh
fi

req_ver aws 2.8.7 awscli

set_aws_account_id()
{
    local aws_account_id="$1"
    export AWS_ACCOUNT_ID="$aws_account_id"
}

set_aws_sso_id()
{
    local aws_sso_id="$1"
    export AWS_SSO_ID="$aws_sso_id"
}

set_aws_sso_role_name()
{
    local aws_sso_role_name="$1"
    export AWS_SSO_ROLE_NAME="$aws_sso_role_name"
}

set_aws_sso_region()
{
    local resource_region="$1"
    export AWS_SSO_REGION="$resource_region"
}

check_aws_login_sso()
{
    log "Checking access to AWS Cluster $(ab "${CLUSTER_NAME}"), it could take a while, please be patient and ignore direnv warnings..."

    local awsConfig="$HOME/.aws/config"
    if grep "\[profile $AWS_PROFILE\]" "$awsConfig" >/dev/null 2>&1; then
        log "Found profile $(ab "${AWS_PROFILE}") in AWS config file $(ab "${awsConfig/$HOME/\~}")"
    else
        warn "Couldn't find profile $(ab "${AWS_PROFILE}") in AWS config file $(ab "${awsConfig/$HOME/\~}"), will create it now"
        log "Setting up AWS SSO credentials in order to access SSO ID $(ab "${AWS_SSO_ID}") with SSO role $(ab "${AWS_SSO_ROLE_NAME}") in region $(ab "${CLUSTER_REGION}") (account id: $(ab "${AWS_ACCOUNT_ID}"))"
        aws configure set sso_start_url "https://${AWS_SSO_ID}.awsapps.com/start"
        aws configure set sso_region "${AWS_SSO_REGION}"
        aws configure set sso_account_id "${AWS_ACCOUNT_ID}"
        aws configure set sso_role_name "${AWS_SSO_ROLE_NAME}"
        aws configure set region "${AWS_SSO_REGION}"
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
