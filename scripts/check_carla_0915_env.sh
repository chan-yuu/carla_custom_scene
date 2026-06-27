#!/usr/bin/env bash
set -euo pipefail

ROOT="/mnt/carla0915_rebuild"
CARLA_ROOT="${ROOT}/carla/carla-0.9.15"
UE4_ROOT="${ROOT}/ue/UnrealEngine_4.26"
SR_ROOT="${ROOT}/scenario_runner/scenario_runner-v0.9.15"
VENV="${ROOT}/venvs/carla0915-py38"

printf 'Workspace: %s\n' "${ROOT}"
findmnt -T "${ROOT}" || true
df -hT "${ROOT}" || true

printf '\nSystem:\n'
lsb_release -ds 2>/dev/null || cat /etc/os-release
python --version || true
python3 --version || true
clang --version | head -n 1 || true
clang++ --version | head -n 1 || true
g++-7 --version | head -n 1 || true
cmake --version | head -n 1 || true
ninja --version || true
nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader 2>/dev/null || true

printf '\nSources:\n'
for dir in "${UE4_ROOT}" "${CARLA_ROOT}" "${SR_ROOT}"; do
  if [ -d "${dir}/.git" ]; then
    printf '%s: ' "${dir}"
    git -C "${dir}" describe --tags --always --dirty 2>/dev/null || git -C "${dir}" rev-parse --short HEAD
  else
    printf '%s: missing\n' "${dir}"
  fi
done

printf '\nBuild outputs:\n'
for path in \
  "${UE4_ROOT}/Engine/Binaries/Linux/UE4Editor" \
  "${CARLA_ROOT}/PythonAPI/carla/dist/carla-0.9.15-py3.8-linux-x86_64.egg" \
  "${CARLA_ROOT}/PythonAPI/carla/dist/carla-0.9.15-cp38-cp38-linux_x86_64.whl" \
  "${CARLA_ROOT}/Unreal/CarlaUE4/Binaries/Linux/libUE4Editor-CarlaUE4.so" \
  "${CARLA_ROOT}/Unreal/CarlaUE4/Plugins/Carla/Binaries/Linux/libUE4Editor-Carla.so"; do
  if [ -e "${path}" ]; then
    printf 'OK      %s\n' "${path}"
  else
    printf 'MISSING %s\n' "${path}"
  fi
done

printf '\nPython imports:\n'
if [ -f "${VENV}/bin/activate" ]; then
  # shellcheck disable=SC1090
  source "${VENV}/bin/activate"
fi
export PYTHONPATH="${CARLA_ROOT}/PythonAPI/carla/dist/carla-0.9.15-py3.8-linux-x86_64.egg:${SR_ROOT}:${PYTHONPATH:-}"
python3 - <<'PY' || true
mods = ["carla", "py_trees", "networkx", "numpy", "shapely", "xmlschema", "srunner"]
for name in mods:
    try:
        __import__(name)
        print("OK      " + name)
    except Exception as exc:
        print("MISSING " + name + ": " + repr(exc))
PY
