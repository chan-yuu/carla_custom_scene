#!/usr/bin/env bash
set -euo pipefail

ROOT="/mnt/carla0915_rebuild"
CARLA_ROOT="${ROOT}/carla/carla-0.9.15"
UE4_ROOT="${ROOT}/ue/UnrealEngine_4.26"
UE4EDITOR="${UE4_ROOT}/Engine/Binaries/Linux/UE4Editor"
UPROJECT="${CARLA_ROOT}/Unreal/CarlaUE4/CarlaUE4.uproject"
MAP="/Game/Carla/Maps/Town01_Opt"
DETACH=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --map)
      MAP="$2"
      shift 2
      ;;
    --detach)
      DETACH=1
      shift
      ;;
    *)
      break
      ;;
  esac
done

mkdir -p "${ROOT}/ddc" "${ROOT}/test_logs"
export UE_LocalDataCachePath="${ROOT}/ddc"

clean_env=(
  env
  "UE-LocalDataCachePath=${ROOT}/ddc"
  -u PYTHONHOME
  -u PYTHONPATH
  -u VIRTUAL_ENV
  -u CONDA_PREFIX
  -u CONDA_DEFAULT_ENV
  "${UE4EDITOR}"
  "${UPROJECT}"
  "${MAP}"
  -vulkan
)

if [ "${DETACH}" -eq 1 ]; then
  log="${ROOT}/test_logs/carla_editor_$(date +%Y%m%d_%H%M%S).log"
  setsid "${clean_env[@]}" "$@" >"${log}" 2>&1 &
  printf 'Started UE4Editor pid=%s log=%s\n' "$!" "${log}"
else
  "${clean_env[@]}" "$@"
fi
