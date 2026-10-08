#!/usr/bin/env python3
"""Fail the build when the AUv3 extension is missing or misconfigured."""
import plistlib
import sys
from pathlib import Path
app = Path(sys.argv[1])
extension = app / 'PlugIns' / 'AirExtension.appex'
with (app / 'Info.plist').open('rb') as handle:
    app_info = plistlib.load(handle)
with (extension / 'Info.plist').open('rb') as handle:
    info = plistlib.load(handle)
assert info['CFBundleIdentifier'].startswith(app_info['CFBundleIdentifier'] + '.')
assert info['CFBundleVersion'] == app_info['CFBundleVersion']
assert (extension / info['CFBundleExecutable']).is_file()
attributes = info['NSExtension']
assert attributes['NSExtensionPointIdentifier'] == 'com.apple.AudioUnit-UI'
assert attributes['NSExtensionPrincipalClass'] == 'AirViewController'
component = attributes['NSExtensionAttributes']['AudioComponents'][0]
assert all(len(component[key]) == 4 for key in ('manufacturer', 'type', 'subtype'))
assert component['type'] == 'aufx'
print('AUv3 bundle validated:', info['CFBundleIdentifier'])
