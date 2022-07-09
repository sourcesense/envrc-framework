#!/usr/bin/env bash

# use as: ./release.sh vX.Y.Z
version="$1"
if [[ -z "$version" ]]; then
    echo >&2 "Missing version, please give a single parameter with version."
    exit 1
fi

sedi=(-i) # use "${sedi[@]}" instead of -i in sed options
case "$(uname)" in
    Darwin*) sedi=(-i "")
esac

previous="_bootstrap.sh" \

filesSeries=(\
    ".envrc-k8s.sh" \
    ".envrc-clusters.sh"
)

filesParallel=(\
    ".envrc-azure.sh" \
    ".envrc-aws-sso.sh" \
    ".envrc-gcp.sh"
)

for file in "${filesSeries[@]}"; do
    hash=$(openssl dgst -sha256 -binary "$previous" | openssl base64 -A)
    cleanedHash="$(echo -e "sha256-$hash" | tr "/" "_")"
    sed "${sedi[@]}" -e "s#\(.*\)/envrc-framework/\(.*\)/\(.*\)#\1/envrc-framework/$version/\3#g" "${file}"
    sed "${sedi[@]}" -e "s#\(.*\)\(sha256.*\)\"#\1$cleanedHash\"#g" "${file}"
    previous="${file}"
done

for file in "${filesParallel[@]}"; do
    hash=$(openssl dgst -sha256 -binary "$previous" | openssl base64 -A)
    cleanedHash="$(echo -e "sha256-$hash" | tr "/" "_")"
    sed "${sedi[@]}" -e "s#\(.*\)/envrc-framework/\(.*\)/\(.*\)#\1/envrc-framework/$version/\3#g" "${file}"
    sed "${sedi[@]}" -e "s#\(.*\)\(sha256.*\)\"#\1$cleanedHash\"#g" "${file}"
done
