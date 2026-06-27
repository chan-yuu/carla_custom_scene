#!/usr/bin/env bash
set -euo pipefail

ROOT="/mnt/carla0915_rebuild"
CARLA_DIR="${ROOT}/carla/carla-0.9.15"
UE_DIR="${ROOT}/ue/UnrealEngine_4.26"
SR_DIR="${ROOT}/scenario_runner/scenario_runner-v0.9.15"

mkdir -p "${ROOT}/carla" "${ROOT}/ue" "${ROOT}/scenario_runner" "${ROOT}/build_logs"

if [ ! -d "${UE_DIR}/.git" ]; then
  git clone --depth 1 -b carla https://github.com/CarlaUnreal/UnrealEngine.git "${UE_DIR}"
else
  git -C "${UE_DIR}" fetch --depth 1 origin carla
  git -C "${UE_DIR}" checkout carla
fi

if [ ! -d "${CARLA_DIR}/.git" ]; then
  git clone https://github.com/carla-simulator/carla.git "${CARLA_DIR}"
fi
git -C "${CARLA_DIR}" fetch origin 0.9.15
git -C "${CARLA_DIR}" checkout 0.9.15
git -C "${CARLA_DIR}" submodule update --init --recursive

if [ ! -d "${SR_DIR}/.git" ]; then
  git clone https://github.com/carla-simulator/scenario_runner.git "${SR_DIR}"
fi
git -C "${SR_DIR}" fetch origin v0.9.15
git -C "${SR_DIR}" checkout v0.9.15

printf 'UE commit: '
git -C "${UE_DIR}" rev-parse --short HEAD
printf 'CARLA commit: '
git -C "${CARLA_DIR}" rev-parse --short HEAD
printf 'ScenarioRunner commit: '
git -C "${SR_DIR}" rev-parse --short HEAD
