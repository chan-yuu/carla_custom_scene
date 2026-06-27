# CARLA Latest Current Status

Updated: 2026-06-28 CST

## Mount

Current command path:

```text
/mnt/carla_latest
```

Visible mount path on this machine:

```text
/media/cyun/新加卷1/disk_4090_2/carla_latest
```

Mount script:

```text
/media/cyun/新加卷1/disk_4090_2/mount_carla.sh
```

Backing ext4 image:

```text
/media/cyun/新加卷1/disk_4090_2/.carla_latest_overlay_store.ext4
```

Only the root workspace overlay should be mounted. `Content/Carla` should be a
normal directory, not another mount.

## Current Build State

```text
UE4 source:             present
UE4 build:              complete
UE4Editor binary:       /mnt/carla_latest/ue/UnrealEngine_4.26/Engine/Binaries/Linux/UE4Editor
CARLA source:           present, upstream 0.9.15, local download/build fixes applied
ScenarioRunner source:  present, v0.9.15
Python venv:            present, Python 3.8
CARLA assets:           installed, version 20231108_c5101a5
CARLA PythonAPI:        complete
CARLA UE4 plugins:      complete
CARLA Editor target:    complete
```

Verified build outputs:

```text
/mnt/carla_latest/carla/carla-0.9.15/PythonAPI/carla/dist/carla-0.9.15-py3.8-linux-x86_64.egg
/mnt/carla_latest/carla/carla-0.9.15/PythonAPI/carla/dist/carla-0.9.15-cp38-cp38-linux_x86_64.whl
/mnt/carla_latest/carla/carla-0.9.15/Unreal/CarlaUE4/Binaries/Linux/libUE4Editor-CarlaUE4.so
/mnt/carla_latest/carla/carla-0.9.15/Unreal/CarlaUE4/Plugins/Carla/Binaries/Linux/libUE4Editor-Carla.so
```

Verified Python packages in the main venv:

```text
carla 0.9.15
numpy 1.18.4
networkx 2.2
pygame 2.6.1
opencv-python 4.2.0.32
Shapely 1.7.1
xmlschema 1.0.18
ScenarioRunner import path available through /mnt/carla_latest/scenario_runner/scenario_runner-v0.9.15
```

`open3d` is intentionally not kept in the main venv because current Open3D
wheels pull a newer NumPy stack that breaks ScenarioRunner's pinned
`networkx==2.2` on this CARLA 0.9.15 setup.

## Useful Paths

```text
UE4:            /mnt/carla_latest/ue/UnrealEngine_4.26
CARLA:          /mnt/carla_latest/carla/carla-0.9.15
ScenarioRunner: /mnt/carla_latest/scenario_runner/scenario_runner-v0.9.15
Python venv:    /mnt/carla_latest/venvs/carla0915-py38
CARLA assets:   /mnt/carla_latest/carla/carla-0.9.15/Unreal/CarlaUE4/Content/Carla
```

No top-level `assets/`, `patches/`, `ddc/`, `scripts/`, `build_logs/`,
`test_logs/`, or `downloads/` directory is required for the install record.
UE/CARLA can recreate caches and logs when needed.

## Filled Workspace Data

The workspace helper directories now contain useful seed data:

```text
custom_assets/reference_index/       indexes of installed CARLA assets by category
hdmap_raw/source_hdmap/carla_maps/   copied CARLA Town OpenDRIVE .xodr files
hdmap_raw/source_hdmap/opendrive/    PythonAPI OpenDRIVE sample, including TownBig.xodr
roadrunner/README.md                 RoadRunner project/export layout notes
scenarios/openscenario/examples/     ScenarioRunner .xosc and .osc examples
scenarios/xml/examples/              ScenarioRunner XML examples
scenarios/routes/                    ScenarioRunner route XML files
```

## Launch UE4 Standalone

```bash
cd /mnt/carla_latest/ue/UnrealEngine_4.26
Engine/Binaries/Linux/UE4Editor -vulkan -nop4
```

## Rebuild CARLA If Needed

The current build is complete. Rebuild only when source changes:

```bash
export UE4_ROOT=/mnt/carla_latest/ue/UnrealEngine_4.26
source /mnt/carla_latest/venvs/carla0915-py38/bin/activate
cd /mnt/carla_latest/carla/carla-0.9.15

make -j"$(nproc)" setup
make -j"$(nproc)" PythonAPI
make -j"$(nproc)" CarlaUE4Editor
```

## Launch CARLA Editor

After CARLA assets and plugins are built:

```bash
/mnt/carla_latest/ue/UnrealEngine_4.26/Engine/Binaries/Linux/UE4Editor \
  /mnt/carla_latest/carla/carla-0.9.15/Unreal/CarlaUE4/CarlaUE4.uproject \
  /Game/Carla/Maps/Town01_Opt \
  -vulkan -nosound -nop4
```

On this machine, use the NVIDIA Vulkan ICD to avoid UE4 enumerating Mesa
`llvmpipe` and printing a handled Vulkan VendorId ensure:

```bash
VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json \
/mnt/carla_latest/ue/UnrealEngine_4.26/Engine/Binaries/Linux/UE4Editor \
  /mnt/carla_latest/carla/carla-0.9.15/Unreal/CarlaUE4/CarlaUE4.uproject \
  /Game/Carla/Maps/Town01_Opt \
  -vulkan -nosound -nop4 -preferNvidia
```
