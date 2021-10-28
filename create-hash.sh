#!/usr/bin/env bash

file2calc="$1"
if [[ -z "$file2calc" ]] ; then
    >&2 echo "Missing filename, please give a single parameter with filename."
    exit 1
fi

hash=$(openssl dgst -sha256 -binary "$file2calc" |openssl base64 -A)
echo -e "normal hash:\nsha256-$hash\n\ncleaned hash:"
echo -e "sha256-$hash"| tr "/" "_"
