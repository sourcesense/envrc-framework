#!/usr/bin/env bash

export _DEP_VERBOSENESS_LEVEL=0

# shellcheck source=/_dep-bootstrap.sh
. "$(fetchurl "https://raw.githubusercontent.com/EcoMind/envrc-framework/v0.13.0/_dep-bootstrap.sh" "sha256-lOYbrk89hNgXowWn1q17tpqUeNnEXJLyDTl7mLhbcpU=")" 0.5.1

dep define "log2/shell-common:0.5.2"
dep define "EcoMind/k8s-common:0.2.13"

dep include log2/shell-common strings
dep include log2/shell-common log
dep include log2/shell-common req
dep include log2/shell-common files
dep include log2/shell-common calc