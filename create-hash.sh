#!/usr/bin/env bash

file2calc="$1"
if [[ -z "$file2calc" ]]; then
    echo >&2 "Missing filename, please give a single parameter with filename."
    exit 1
fi

hash=$(openssl dgst -sha256 -binary "$file2calc" | openssl base64 -A)
rawHash="sha256-${hash}"
cleanedHash="$(echo -e "sha256-$hash" | tr "/" "_")"
echo -e "normal hash:\n$rawHash\n"
echo -e "cleaned hash:\n$cleanedHash"
echo -n "$cleanedHash" | pbcopy
echo "(copied to clipboard)"
