#!/bin/bash -

### handle arguments

color=accentColor
case $# in
2)
    app="$1"
    color="$2"
    ;;
1)
    app="$1"
    ;;
*)
    echo "usage: $0 app_name [color_name]"
    echo "  e.g. $0 pines warningTextColor"
    exit 1
esac

colorset="Source/${app}_app/${app}.xcassets/${color}.colorset/Contents.json"
test -r "$colorset" || { echo "no such file: $colorset"; exit 1; }

### scrape color set to get RGB

set -e

baseurl="https://webaim.org/resources/contrastchecker/"
light_bg="FFFFFF"
dark_bg="1C1C1E"

# select the RGB of the "any" or "light" appearance
echo "read $colorset"
rgb=$(cat "$colorset" | jq -r '

  .colors[]
| {
    appearance: (.appearances[0].value // "any"),
    rgb: (
      [.color.components.red[2:], .color.components.green[2:], .color.components.blue[2:]]
      | join("")
    )
  }
| select(.appearance == "any" or .appearance == "light")
| .rgb
')
url="${baseurl}?scheme=${app}-ios-light&bcolor=${light_bg}&fcolor=${rgb}"
echo "open $url"
open "$url"

# select the RGB of the "dark" appearance
rgb=$(cat "$colorset" | jq -r '

  .colors[]
| {
    appearance: (.appearances[0].value // "any"),
    rgb: (
      [.color.components.red[2:], .color.components.green[2:], .color.components.blue[2:]]
      | join("")
    )
  }
| select(.appearance == "dark")
| .rgb
')
url="${baseurl}?scheme=${app}-ios-dark&bcolor=${dark_bg}&fcolor=${rgb}"
echo "open $url"
open "$url"
