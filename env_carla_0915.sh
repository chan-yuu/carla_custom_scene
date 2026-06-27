#!/usr/bin/env bash

export CARLA_PROJECT_ROOT="/mnt/carla0915_rebuild"
export CARLA_ROOT="${CARLA_PROJECT_ROOT}/carla/carla-0.9.15"
export UE4_ROOT="${CARLA_PROJECT_ROOT}/ue/UnrealEngine_4.26"
export SCENARIO_RUNNER_ROOT="${CARLA_PROJECT_ROOT}/scenario_runner/scenario_runner-v0.9.15"
export CARLA_PY38_VENV="${CARLA_PROJECT_ROOT}/venvs/carla0915-py38"
export CARLA_EGG="${CARLA_ROOT}/PythonAPI/carla/dist/carla-0.9.15-py3.8-linux-x86_64.egg"

if [ -f "${CARLA_PY38_VENV}/bin/activate" ]; then
  # shellcheck disable=SC1091
  source "${CARLA_PY38_VENV}/bin/activate"
fi

export PYTHONPATH="${CARLA_EGG}:${SCENARIO_RUNNER_ROOT}:${PYTHONPATH:-}"
