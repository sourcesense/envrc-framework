#!/usr/bin/env bash

export _DEP_VERBOSENESS_LEVEL=0

# shellcheck source=/_dep-bootstrap.sh
. "$(fetchurl "https://raw.githubusercontent.com/EcoMind/dep-bootstrap/0.5.2/dep-bootstrap.sh" "sha256-bvm1j_suhjKpGwGrsnC3iVYbyJngyyvAxIyD3LNiH2s=")" 0.5.2

dep define "log2/shell-common:0.5.12"
dep define "EcoMind/k8s-common:0.2.26"

dep include log2/shell-common strings
dep include log2/shell-common log
dep include log2/shell-common req
dep include log2/shell-common files
dep include log2/shell-common calc
