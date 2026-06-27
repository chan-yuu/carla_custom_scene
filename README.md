# CARLA Latest

Clean overlay workspace for a CARLA 0.9.15 source build and custom scene work.

Current status:

```text
UE4 4.26 build:        complete
CARLA 0.9.15 build:    complete
CARLA Content version: 20231108_c5101a5
PythonAPI:             built and installed in venv
ScenarioRunner:        present, v0.9.15
```

Mount the workspace:

```bash
/media/cyun/新加卷1/disk_4090_2/mount_carla.sh
```

Use the ASCII command path after mounting:

```bash
cd /mnt/carla_latest
```

The visible path is the same workspace:

```text
/media/cyun/新加卷1/disk_4090_2/carla_latest
```

UE4 standalone launch after the engine is built:

```bash
cd /mnt/carla_latest/ue/UnrealEngine_4.26
Engine/Binaries/Linux/UE4Editor -vulkan -nop4
```

CARLA editor launch:

```bash
VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json \
/mnt/carla_latest/ue/UnrealEngine_4.26/Engine/Binaries/Linux/UE4Editor \
  /mnt/carla_latest/carla/carla-0.9.15/Unreal/CarlaUE4/CarlaUE4.uproject \
  /Game/Carla/Maps/Town01_Opt \
  -vulkan -nosound -nop4 -preferNvidia
```

Use the `VK_ICD_FILENAMES` prefix on this machine to keep UE4 from enumerating
Mesa `llvmpipe` as a Vulkan device.

See:

```text
docs/overlay_usage.md
docs/project_layout.md
docs/local_install_status.md
docs/local_build_process.md
docs/custom_map_workflow.md
docs/create_custom_town_zh.md
```
