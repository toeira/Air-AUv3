#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
app_path="build/DerivedData/Build/Products/Release-iphoneos/Air.app"
test -d "$app_path"
test -d "$app_path/PlugIns/AirExtension.appex"
python3 scripts/validate_bundle.py "$app_path"
mkdir -p build/package/Payload
rm -rf build/package/Payload/Air.app
cp -R "$app_path" build/package/Payload/Air.app
cd build/package
zip -qry ../Air_AUv3_unsigned.ipa Payload
