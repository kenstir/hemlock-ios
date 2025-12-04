#!/bin/sh

if [ $# -ne 1 ]; then
    echo "usage: $0 app_name"
    exit 1
fi
app="$1"

proj="Hemlock.xcodeproj/project.pbxproj"

set -e

app=owwl
scheme=OWWL

xcodebuild archive \
  -scheme "$scheme" \
  -configuration Release \
  -destination generic/platform=iOS \
  -archivePath build/$app.xcarchive

xcodebuild -exportArchive \
           -archivePath build/$app.xcarchive \
           -exportOptionsPlist tools/ExportOptions.plist \
           -exportPath build/export

#  SKIP_INSTALL=NO

echo exit early
exit 1

# 1. build + archive
xcodebuild -scheme PINES -archivePath build/PINES.xcarchive archive
# 2. export .ipa
#
xcodebuild -exportArchive \
  -archivePath build/PINES.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist tools/ExportOptions.plist
# 3. upload
xcrun iTMSTransporter \
  -m upload \
  -assetFile build/export/PINES.ipa \
  -u "your-apple-id@example.com" \
  -p "your-app-specific-password"
## OR
# upload from an archive
xcodebuild -upload-app -archivePath build/PINES.xcarchive \
  -exportOptionsPlist tools/ExportOptions.plist

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
/Applications/Transporter.app/Contents/itms/bin/iTMSTransporter -m upload -assetFile build/export/OWWL.ipa -s FCHUE4234N -u kenstir@gmail.com -p ohmu-urel-vwco-kvkl -v eXtreme
