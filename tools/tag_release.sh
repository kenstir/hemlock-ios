#!/bin/sh

if [ $# -ne 1 ]; then
    echo "usage: $0 app_name"
    exit 1
fi
app="$1"

proj="Hemlock.xcodeproj/project.pbxproj"

set -e

## find the plist identifier of the XCBuildConfiguration Release section for the given app

buildver=$(cat "$proj" \
    | sed -ne '/Begin XCBuildConfiguration section/,/End XCBuildConfiguration section/ p' \
    | awk '
    BEGIN {
        app_matches = 0
    }

    # Store the identifier of Debug or Release blocks
    /[A-F0-9]+ \/\* (Debug|Release) \*\// {
        IDENT = $1
        #print NR, $0
    }

    # If the app matches, we are in the right block
    /INFOPLIST_FILE.*\/'$app'_app/ {
        #print NR, $0
        #print IDENT
        app_matches = 1
    }

    # Get out at the end of the match block
    /};/ {
        if (app_matches) {
           #print NR, $0
           exit
        }
    }

    # Extract BUILD (includes semicolon)
    /CURRENT_PROJECT_VERSION = / {
        BUILD = $3
    }

    # Extract VERSION (includes semicolon)
    /MARKETING_VERSION = / {
        VERSION = $3
    }

    END {
        if (app_matches) {
            print "BUILD=" BUILD
            print "VERSION=" VERSION
        } else {
            print "false"
        }
    }
')

echo "$buildver"
eval "$buildver" || { echo >&2 failed to parse BUILD and VERSION; exit 1; }
test -n "$BUILD"
test -n "$VERSION"

## Construct a tag and tag it

set -ex

tag=${app}_${VERSION}.${BUILD}
msg="${tag}"

git commit "$proj" -m "$msg" || true
git tag -a -m "$msg" $tag
git push
git push origin $tag
