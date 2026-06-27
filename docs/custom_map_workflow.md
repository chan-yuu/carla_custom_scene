# CARLA Custom Map Workflow

Updated: 2026-06-28 CST

This document describes the custom-map workflow for the new CARLA 0.9.15
workspace:

```text
/mnt/carla_latest
```

The visible overlay path is:

```text
/media/cyun/新加卷1/disk_4090_2/carla_latest
```

Use `/mnt/carla_latest` in commands.

Chinese step-by-step guide for creating a new Town:

```text
docs/create_custom_town_zh.md
```

## 1. Workspace Directories

The new workspace is intentionally laid out for source build and custom maps:

```text
/mnt/carla_latest
├── carla/carla-0.9.15
├── ue/UnrealEngine_4.26
├── scenario_runner/scenario_runner-v0.9.15
├── venvs/carla0915-py38
├── hdmap_raw
│   ├── pointcloud
│   └── source_hdmap
├── roadrunner
│   ├── project
│   └── export
├── custom_assets
│   ├── buildings
│   ├── fences
│   ├── poles
│   ├── textures
│   └── vegetation
└── scenarios
    ├── openscenario
    └── routes
```

Directory roles:

```text
carla:          CARLA source, Unreal project, PythonAPI, plugins
ue:             CARLA fork UE 4.26 source and build products
scenario_runner: ScenarioRunner v0.9.15
venvs:          Python 3.8 virtual environment
hdmap_raw:      PCD, raw HD maps, coordinate-system notes
roadrunner:     RoadRunner projects and exported FBX/XODR/RRDATA
custom_assets:  buildings, fences, poles, vegetation, textures
scenarios:      OpenSCENARIO files, route XML, ScenarioRunner inputs
```

The previous `/mnt/carla_compiled` installation is a historical reference only.
Do not put new custom-map files there.

## 2. RoadRunner Role

RoadRunner is MathWorks' road-scene editor. For CARLA custom maps, it is mainly
used to keep road logic and visible geometry aligned.

It usually handles:

```text
1. Road plan, lanes, junctions, sidewalks, parking zones.
2. PCD, aerial/GIS, CAD, or HD-map reference alignment.
3. OpenDRIVE connectivity, lane direction, junction, marking, and signal checks.
4. CARLA-oriented export:
   - <MapName>.xodr
   - <MapName>.fbx
   - <MapName>.rrdata.xml
```

File roles:

```text
XODR:
  OpenDRIVE road logic. CARLA uses it for waypoints, lanes, junctions,
  routes, Traffic Manager, lane invasion, and landmarks.

FBX:
  Visible UE4 geometry. Roads, sidewalks, ground, shoulders, and base
  infrastructure need mesh geometry in Unreal Editor.

RRDATA:
  RoadRunner-to-CARLA import metadata, including material, semantic, and
  signal-related information.

PCD:
  Point cloud reference data. It is useful for reconstruction/alignment but is
  not a complete runnable CARLA map by itself.
```

If an `.xodr` already exists, RoadRunner can still be useful for checking and
repairing intersections, lane markings, stop lines, traffic signals, and for
exporting an aligned FBX.

## 3. PCD/XODR To CARLA Map

If the starting data is:

```text
*.pcd
*.xodr
```

then a complete CARLA Town still needs at least:

```text
*.fbx
```

Minimum practical workflow:

```text
PCD / HD map / CAD / aerial reference
        ↓
Coordinate-system cleanup, map origin selection, ENU/UE alignment
        ↓
Check or repair XODR
        ↓
Generate road/ground FBX aligned with XODR
        ↓
Place import package under CARLA Import
        ↓
make import
        ↓
Open in UE4Editor and add materials, collision, semantic tags, traffic objects
        ↓
Generate pedestrian nav .bin and TM data when needed
        ↓
Validate with CARLA PythonAPI and ScenarioRunner
        ↓
make package, optional
```

Minimal import package:

```text
/mnt/carla_latest/carla/carla-0.9.15/Import
└── TianjinRoadPackage
    ├── TianjinRoadPackage.json
    └── TianjinRoad
        ├── TianjinRoad.fbx
        └── TianjinRoad.xodr
```

JSON example:

```json
{
  "maps": [
    {
      "name": "TianjinRoad",
      "source": "./TianjinRoad/TianjinRoad.fbx",
      "use_carla_materials": true,
      "xodr": "./TianjinRoad/TianjinRoad.xodr"
    }
  ],
  "props": []
}
```

Import command:

```bash
cd /mnt/carla_latest/carla/carla-0.9.15
make import ARGS="--package=TianjinRoadPackage"
```

Expected generated content:

```text
/mnt/carla_latest/carla/carla-0.9.15/Unreal/CarlaUE4/Content/TianjinRoadPackage
```

Open it in UE4Editor:

```bash
/mnt/carla_latest/ue/UnrealEngine_4.26/Engine/Binaries/Linux/UE4Editor \
  /mnt/carla_latest/carla/carla-0.9.15/Unreal/CarlaUE4/CarlaUE4.uproject \
  /Game/TianjinRoadPackage/Maps/TianjinRoad \
  -vulkan \
  -nosound -nop4
```

UE4 checklist:

```text
1. Check that visible map geometry and XODR logic align.
2. Add or fix road materials, decals, and lane markings.
3. Add collision to roads, buildings, guardrails, walls, and props.
4. Set semantic tags for segmentation sensors.
5. Place buildings, walls, lamps, trees, signs, and traffic light poles.
6. Check PlayerStart and spawn points.
7. Check traffic light trigger volumes against stop lines.
8. Save all maps and sublevels.
```

XODR-only testing is possible through CARLA's OpenDRIVE standalone mode, but it
does not create a complete UE4 city scene. It is useful for quick road-logic
checks, not for the final custom Town.

## 4. UE4Editor Project

The editor opens the CARLA UE4 project, not the raw UE engine directory:

```text
project file:
/mnt/carla_latest/carla/carla-0.9.15/Unreal/CarlaUE4/CarlaUE4.uproject

project root:
/mnt/carla_latest/carla/carla-0.9.15/Unreal/CarlaUE4

UE4Editor binary:
/mnt/carla_latest/ue/UnrealEngine_4.26/Engine/Binaries/Linux/UE4Editor
```

Command shape:

```bash
/mnt/carla_latest/ue/UnrealEngine_4.26/Engine/Binaries/Linux/UE4Editor \
  /mnt/carla_latest/carla/carla-0.9.15/Unreal/CarlaUE4/CarlaUE4.uproject \
  /Game/Carla/Maps/Town01_Opt \
  -vulkan -nosound -nop4
```

Official CARLA assets for the new workspace should live directly under the
standard CARLA content path:

```text
/mnt/carla_latest/carla/carla-0.9.15/Unreal/CarlaUE4/Content/Carla
```

Do not add a second bind mount at `Content/Carla`; the root workspace overlay is
the only intended mount layer.

In the UE4 Content Browser, `/Game/Carla/...` corresponds to the
`Unreal/CarlaUE4/Content/Carla/...` content path.

## 5. Complete Map Contents

Using official `Town01_Opt` as the model, a complete map is a group of UE assets,
OpenDRIVE files, navigation files, and supporting data.

Core files:

```text
Content/Carla/Maps/Town01_Opt.umap
Content/Carla/Maps/OpenDrive/Town01_Opt.xodr
Content/Carla/Maps/Nav/Town01_Opt.bin
Content/Carla/Maps/TM/Town01_Opt.bin
Content/Carla/Maps/Town01_BuiltData.uasset
```

`Town01_Opt.umap` is the main level. `Town01_Opt.xodr` is the road logic.
`Nav/Town01_Opt.bin` is pedestrian navigation. `TM/Town01_Opt.bin` is Traffic
Manager data. `BuiltData.uasset` stores built lighting and related UE data.

Official maps also use sublevels such as:

```text
Content/Carla/Maps/Sublevels/Town01_Opt/T01_Ground.umap
Content/Carla/Maps/Sublevels/Town01_Opt/T01_Parked_Vehicles.umap
Content/Carla/Maps/Sublevels/Town01_Opt/T01_Buildings.umap
Content/Carla/Maps/Sublevels/Town01_Opt/T01_Rendering_and_Lightning_components.umap
Content/Carla/Maps/Sublevels/Town01_Opt/T01_Decals.umap
Content/Carla/Maps/Sublevels/Town01_Opt/T01_Foliage.umap
Content/Carla/Maps/Sublevels/Town01_Opt/T01_Props.umap
Content/Carla/Maps/Sublevels/Town01_Opt/T01_Walls.umap
Content/Carla/Maps/Sublevels/Town01_Opt/T01_Layout.umap
Content/Carla/Maps/Sublevels/Town01_Opt/T01_Streetlights.umap
```

Suggested custom package structure:

```text
Content/TianjinRoadPackage
├── Config
├── Maps
│   ├── TianjinRoad.umap
│   ├── OpenDrive/TianjinRoad.xodr
│   ├── Nav/TianjinRoad.bin
│   ├── TM/TianjinRoad.bin
│   └── Sublevels/TianjinRoad/...
├── Static
├── Materials
├── Textures
└── Blueprints
```

Minimum runnable custom map:

```text
TianjinRoad.umap
OpenDrive/TianjinRoad.xodr
road/ground mesh
basic materials
collision
```

Add these as the map matures:

```text
Nav .bin
TM .bin
traffic lights / signs
semantic tags
sublevels
props / buildings / vegetation
ScenarioRunner routes and scenarios
```
