#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

xcconfig=$(mktemp /tmp/static.xcconfig.XXXXXX)
trap 'rm -f "$xcconfig"' INT TERM HUP EXIT
echo "ONLY_ACTIVE_ARCH[sdk=iphonesimulator*] = YES" >>$xcconfig
export XCODE_XCCONFIG_FILE="$xcconfig"

carthage update --platform ios $@
