#!/bin/sh

if [ $# -le 2 ]; then
    echo "usage: $0 from_app to_app asset..."
    exit 1
fi
src="$1"; shift
dst="$1"; shift

set -e

## verify args

pushd Source/${src}_app/*.xcassets
for i in "$@"; do
    if [ ! -d "$i" ]; then
        echo >&2 $i: No such directory
        exit 1
    fi
done
popd

## copy assets

tar -C Source/${src}_app/*.xcassets -cf - "$@" \
    | tar -C Source/${dst}_app/*.xcassets -xvf -
