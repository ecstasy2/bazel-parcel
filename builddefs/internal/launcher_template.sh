#!/usr/bin/env bash

# Copyright 2018 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Immediately exit if any command fails.

set -euo pipefail
# --- begin runfiles.bash initialization ---
if [[ ! -d "${RUNFILES_DIR:-/dev/null}" && ! -f "${RUNFILES_MANIFEST_FILE:-/dev/null}" ]]; then
    if [[ -f "$0.runfiles_manifest" ]]; then
      export RUNFILES_MANIFEST_FILE="$0.runfiles_manifest"
    elif [[ -f "$0.runfiles/MANIFEST" ]]; then
      export RUNFILES_MANIFEST_FILE="$0.runfiles/MANIFEST"
    elif [[ -f "$0.runfiles/bazel_tools/tools/bash/runfiles/runfiles.bash" ]]; then
      export RUNFILES_DIR="$0.runfiles"
    fi
fi
if [[ -f "${RUNFILES_DIR:-/dev/null}/bazel_tools/tools/bash/runfiles/runfiles.bash" ]]; then
  source "${RUNFILES_DIR}/bazel_tools/tools/bash/runfiles/runfiles.bash"
elif [[ -f "${RUNFILES_MANIFEST_FILE:-/dev/null}" ]]; then
  source "$(grep -m1 "^bazel_tools/tools/bash/runfiles/runfiles.bash " \
            "$RUNFILES_MANIFEST_FILE" | cut -d ' ' -f 2-)"
else
  echo >&2 "ERROR: cannot find @bazel_tools//tools/bash/runfiles:runfiles.bash"
  exit 1
fi
# --- end runfiles.bash initialization ---

runfiles_export_envvars

readonly main=$(rlocation "TEMPLATED_main")
readonly index_html=$(rlocation "TEMPLATED_index_html")
readonly manifest=$(rlocation "TEMPLATED_manifest")
readonly scripts_manifest=$(rlocation "TEMPLATED_scripts_manifest")
readonly entry_module=TEMPLATED_entry_module
readonly serving_path=TEMPLATED_serving_path
readonly packages=TEMPLATED_packages

# TEMPLATED_packages
# TEMPLATED_scripts_manifest

# Workaround for https://github.com/bazelbuild/bazel/issues/6764
# If this issue is incorporated into Bazel, the workaround here should be removed.
"${main}" serve --port=5432 --log-level 3 --no-autoinstall $index_html