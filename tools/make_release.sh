#!/bin/sh
#
# make_release.sh -
#
#       Make release IPA and upload to TestFlight
#
#       Intended for use by fastlane
#
# usage: tools/fl make_release app:pines

if [ $# -ne 1 ]; then
    echo "usage: $0 app_name"
    exit 1
fi
app="$1"

proj="Hemlock.xcodeproj/project.pbxproj"

set -e

# scheme name is now the same as the app

scheme="$app"

# collect other metadata from Secrets/

teamid=$(cat Secrets/teamid.kenstir)
if [ -r Secrets/teamid.$app ]; then
    teamid=$(cat Secrets/teamid.$app)
fi
username=$(cat Secrets/transport.username)
password=$(cat Secrets/transport.password)

# trust but verify

echo "teamid:   $teamid"
echo "username: $username"
test -n "$teamid"
test -n "$username"
test -n "$password"

echo ""
#read -p "Continue ?" ans

# build .xcarchive

xcodebuild archive \
  -scheme "$scheme" \
  -configuration Release \
  -destination generic/platform=iOS \
  -archivePath build/$app.xcarchive

# build .ipa

xcodebuild -exportArchive \
           -archivePath build/$app.xcarchive \
           -exportOptionsPlist tools/ExportOptions.plist \
           -exportPath build/export

# upload it

/Applications/Transporter.app/Contents/itms/bin/iTMSTransporter \
    -m upload \
    -assetFile build/export/$scheme.ipa \
    -s "$teamid" \
    -u "$username" \
    -p "$password" \
    -v eXtreme
