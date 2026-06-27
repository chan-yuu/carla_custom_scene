# CARLA Latest Project Layout

Updated: 2026-06-27 CST

The repository is a clean CARLA 0.9.15 workspace skeleton. It intentionally
keeps documentation and directory structure only.

Tracked documentation:

```text
docs/overlay_usage.md
docs/project_layout.md
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
├── assets/
├── ddc/
├── build_logs/
├── test_logs/
├── scripts/
├── docs/
├── hdmap_raw/
│   ├── pointcloud/
│   └── source_hdmap/
├── roadrunner/
│   ├── project/
│   └── export/
├── custom_assets/
│   ├── buildings/
│   ├── fences/
│   ├── poles/
│   ├── textures/
│   └── vegetation/
├── scenarios/
│   ├── openscenario/
│   └── routes/
└── tmp/
```

The empty directories are kept for future CARLA source, Unreal Engine,
ScenarioRunner, custom maps, logs, and assets. Heavy generated content should be
created through the mounted workspace path, not copied into documentation.

Git remote:

```text
https://github.com/chan-yuu/carla_custom_scene.git
```
