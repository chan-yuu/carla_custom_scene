# CARLA Latest Project Layout

Updated: 2026-06-28 CST

This repository is the clean CARLA 0.9.15 workspace skeleton for the new
source-build setup.

Primary visible path:

```text
/media/cyun/新加卷1/disk_4090_2/carla_latest
```

Primary command path:

```text
/mnt/carla_latest
```

Use `/mnt/carla_latest` in build and run commands. It is a bind mount of the
same overlay workspace and avoids non-ASCII path issues in UE4/CARLA tooling.

Tracked documentation:

```text
docs/overlay_usage.md
docs/project_layout.md
docs/local_build_process.md
docs/local_install_status.md
docs/custom_map_workflow.md
docs/create_custom_town_zh.md
```

Directory layout:

```text
carla_latest/
├── carla/
│   └── carla-0.9.15/
│       ├── Import/
│       ├── PythonAPI/carla/dist/
│       └── Unreal/CarlaUE4/
│           ├── Binaries/Linux/
│           ├── Content/Carla/
│           └── Plugins/Carla/Binaries/Linux/
├── ue/
│   └── UnrealEngine_4.26/
│       └── Engine/
│           ├── Binaries/Linux/
│           ├── Intermediate/
│           └── Source/
├── scenario_runner/
│   └── scenario_runner-v0.9.15/
├── venvs/
│   └── carla0915-py38/
├── docs/
├── hdmap_raw/
│   ├── README.md
│   ├── pointcloud/
│   └── source_hdmap/
│       ├── carla_maps/
│       └── opendrive/
├── roadrunner/
│   ├── README.md
│   ├── project/
│   └── export/
├── custom_assets/
│   ├── README.md
│   ├── reference_index/
│   ├── buildings/
│   ├── fences/
│   ├── poles/
│   ├── textures/
│   └── vegetation/
├── scenarios/
│   ├── README.md
│   ├── openscenario/
│   ├── routes/
│   └── xml/
```

The directories are used for CARLA source, Unreal Engine, ScenarioRunner,
custom maps, and custom assets. For the new installation, put source trees,
dependencies, build products, CARLA assets, and imported maps under this
workspace.

Planned local paths after bootstrap:

```text
CARLA source:        /mnt/carla_latest/carla/carla-0.9.15
Unreal Engine:       /mnt/carla_latest/ue/UnrealEngine_4.26
ScenarioRunner:      /mnt/carla_latest/scenario_runner/scenario_runner-v0.9.15
Python venv:         /mnt/carla_latest/venvs/carla0915-py38
CARLA assets:        /mnt/carla_latest/carla/carla-0.9.15/Unreal/CarlaUE4/Content/Carla
```

Official CARLA assets are not kept in a top-level `assets/` directory. They are
downloaded by the upstream CARLA `./Update.sh` script and extracted into
`Unreal/CarlaUE4/Content/Carla`. The `custom_assets/` directory is for user
source material such as buildings, textures, vegetation, poles, fences, and
other custom-map inputs.

Seeded workspace content:

```text
custom_assets/reference_index/
  Existing CARLA Content asset indexes for buildings, fences, poles,
  vegetation, and texture/material samples.

hdmap_raw/source_hdmap/carla_maps/
  CARLA Town OpenDRIVE .xodr working copies.

hdmap_raw/source_hdmap/opendrive/
  PythonAPI OpenDRIVE sample files, including TownBig.xodr.

roadrunner/
  Project/export folders plus README notes for RoadRunner-generated files.

scenarios/
  ScenarioRunner examples copied into editable openscenario/xml/routes folders.
```

No top-level `assets/`, `patches/`, `ddc`, `scripts`, `build_logs`,
`test_logs`, or `downloads` directory is required. UE4/CARLA may create cache or
log directories during use, but they are generated data.

Do not use the old `/mnt/carla_compiled` paths as execution targets. They are
only historical references from the previous installation.

Git remote:

```text
https://github.com/chan-yuu/carla_custom_scene.git
```
