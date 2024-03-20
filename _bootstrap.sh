#!/usr/bin/env bash

export _DEP_VERBOSENESS_LEVEL=0

# shellcheck source=/_dep-bootstrap.sh
. "$(fetchurl "https://raw.githubusercontent.com/sourcesense/dep-bootstrap/0.5.5/dep-bootstrap.sh" "sha256-rtqYzq7o1d+rymFH00Cq_tve28vbOKSKxoDFvO0zjd4=")" 0.5.5

dep define "log2/shell-common:0.5.13"
dep define "sourcesense/k8s-common:0.2.29"

dep include log2/shell-common strings
dep include log2/shell-common log
dep include log2/shell-common req
dep include log2/shell-common files
dep include log2/shell-common calc
