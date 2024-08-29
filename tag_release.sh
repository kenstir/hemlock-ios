#!/bin/sh

if [ $# -ne 1 ]; then
    echo "usage: $0 app_name"
    exit 1
fi
app="$1"

proj="Hemlock.xcodeproj/project.pbxproj"

set -e

## find the plist identifier of XCBuildConfiguration section for Debug and Release

cat "$proj" \
    | sed -ne '/Begin XCBuildConfiguration section/,/End XCBuildConfiguration section/ p' \
    | awk '
    # Store the identifier
    /[A-F0-9]+ \/\* (Debug|Release) \*\// {
        IDENT = $1
    }

    # Print the stored identifier
    /CODE_SIGN_ENTITLEMENTS = Source\/'$app'_app/ {
        print IDENT
        exit
    }
'
exit 1


versionCode=$(egrep android:versionCode $manifest)
versionCode=${versionCode#*\"}
versionCode=${versionCode%\"*}
echo versionCode=$versionCode
test -n "$versionCode"

versionName=$(egrep android:versionName $manifest)
versionName=${versionName#*\"}
versionName=${versionName%\"*}
echo versionName=$versionName
test -n "$versionName"

set -ex

tag=${app}_v${versionCode}
msg="${tag} (${versionName})"

git commit core/build.gradle "$manifest" -m "$msg" || true
git tag -a -m "$msg" $tag
git push
#git push --tags
git push origin $tag
