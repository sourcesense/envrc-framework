#!/usr/bin/env bash

if type direnv >/dev/null 2>&1 ; then
    # shellcheck disable=SC1090
    . <(direnv stdlib)
else
    echo "Could not load direnv stdlib" >&2
    exit 1
fi

# shellcheck source=scripts/_base-bootstrap.sh
source_url "https://raw.githubusercontent.com/EcoMind/envrc-framework/v0.3.0/_base-bootstrap.sh" "sha256-npXZIJEwkPXCvku5ucUekumURGRO6zcUcTWDBn1GSbc="
