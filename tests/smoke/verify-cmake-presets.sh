#!/usr/bin/env bash
# Copyright (c) Advanced Micro Devices, Inc. All rights reserved.
#
# SPDX-License-Identifier: MIT
#
# Smoke test: CMakePresets.json parses and exposes expected test presets.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

exec python3 - "$ROOT" <<'PY'
import json
import sys

root = sys.argv[1]
path = f"{root}/CMakePresets.json"
with open(path, encoding="utf-8") as f:
    data = json.load(f)

required = {"unit", "system", "hardware", "sweep", "integration", "all"}
visible = {
    p["name"]
    for p in data.get("testPresets", [])
    if not p.get("hidden")
}
missing = sorted(required - visible)
if missing:
    print("CMakePresets.json missing test presets:", ", ".join(missing))
    sys.exit(1)

print("CMakePresets.json: required test presets present.")
PY
