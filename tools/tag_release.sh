#!/bin/sh

if [ $# -ne 1 ]; then
    echo "usage: $0 app_name"
    exit 1
fi
app="$1"

proj="Hemlock.xcodeproj/project.pbxproj"

set -e

## Scrape version strings from Xcode >> project Hemlock >> Build Settings >> Versioning

version=$(fgrep 'MARKETING_VERSION =' "$proj" | uniq | awk '{print $NF}')
version_uniq=$(fgrep -c 'MARKETING_VERSION =' "$proj" | uniq | wc -l)
if [ "$version_uniq" != 1 ]; then
    echo >&2 "Marketing Version should be set only once at the project level"
    fgrep 'MARKETING_VERSION =' "$proj"
    exit 1
fi

build=$(fgrep 'CURRENT_PROJECT_VERSION =' "$proj" | uniq | awk '{print $NF}')
build_uniq=$(fgrep -c 'CURRENT_PROJECT_VERSION = ' "$proj" | uniq | wc -l)
if [ "$build_uniq" ]; then
    echo >&2 "Current Project Version should be set only once at the project level"
    fgrep 'CURRENT_PROJECT_VERSION =' "$proj"
    exit 1
fi

echo "vers:  $version"
echo "build: $build"
test -n "$build"
test -n "$version"
exit 1

## Construct a tag and tag it

set -ex

tag=${app}_${VERSION}.${BUILD}
msg="${tag}"

git commit "$proj" -m "$msg" || true
git tag -a -m "$msg" $tag
git push
git push origin $tag
