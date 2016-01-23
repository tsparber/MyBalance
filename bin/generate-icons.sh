#!/usr/bin/env bash

cd "$(dirname "$0")"
cd ..

for size in 76 120 152 167 180; do
  destination="MyBalance/Assets.xcassets/AppIcon.appiconset/icon${size}.png"
  inkscape -z -e "${PWD}/${destination}" -w ${size} -h ${size} ${PWD}/Assets/icon-iOS.svg
done
