#!/usr/bin/env bash
set -euo pipefail

ROOT="/mnt/carla0915_rebuild"
# shellcheck disable=SC1091
source "${ROOT}/env_carla_0915.sh"

cd "${SCENARIO_RUNNER_ROOT}"
exec python3 scenario_runner.py "$@"
