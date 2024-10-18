#!/bin/sh

if [ $# -le 2 ]; then
    echo "usage: $0 from_app to_app asset..."
    exit 1
fi
src="$1"; shift
dst="$1"; shift

set -e

## func

function checkdir () {
    dir="$1"
    if [ ! -d "$dir" ]; then
        echo >&2 "$dir: No such directory"
        exit 1
    fi
}

## verify args

srcdir=Source/${src}_app/${src}.xcassets
dstdir=Source/${dst}_app/${dst}.xcassets
checkdir "$srcdir"
checkdir "$dstdir"
for i in "$@"; do
    checkdir "$srcdir/$i"
done

## copy assets

tar -C Source/${src}_app/*.xcassets -cf - "$@" \
    | tar -C Source/${dst}_app/*.xcassets -xvf -
