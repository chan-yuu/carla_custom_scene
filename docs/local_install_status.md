# CARLA 0.9.15 Local Install Status

Updated: 2026-06-26 20:35 CST

## Paths

Use the ASCII build path for all commands:

```bash
cd /mnt/carla_compiled
source /mnt/carla_compiled/env_carla_0915.sh
```

Original project path:

```text
/media/cyun/新加卷/disk_4090/carla_compiled
```

Main components:

```text
CARLA source:        /mnt/carla_compiled/carla/carla-0.9.15
Unreal Engine:       /mnt/carla_compiled/ue/UnrealEngine_4.26
ScenarioRunner:      /mnt/carla_compiled/scenario_runner/scenario_runner-v0.9.15
Python venv:         /mnt/carla_compiled/venvs/carla0915-py38
CARLA assets stage:  /mnt/carla_assets_stage/carla_assets_0915/Carla
```

## Build Status

Completed:

```text
UE 4.26 Setup.sh
UE 4.26 GenerateProjectFiles.sh
UE 4.26 make
CARLA 0.9.15 assets download and extraction
CARLA make PythonAPI
CARLA make CarlaUE4Editor
ScenarioRunner v0.9.15 Python dependencies
```

Verified outputs:

```text
Python egg:
/mnt/carla_compiled/carla/carla-0.9.15/PythonAPI/carla/dist/carla-0.9.15-py3.8-linux-x86_64.egg

Python wheel:
/mnt/carla_compiled/carla/carla-0.9.15/PythonAPI/carla/dist/carla-0.9.15-cp38-cp38-linux_x86_64.whl

Unreal project library:
/mnt/carla_compiled/carla/carla-0.9.15/Unreal/CarlaUE4/Binaries/Linux/libUE4Editor-CarlaUE4.so

CARLA UE plugin:
/mnt/carla_compiled/carla/carla-0.9.15/Unreal/CarlaUE4/Plugins/Carla/Binaries/Linux/libUE4Editor-Carla.so
```

CARLA assets are bind-mounted into the source tree:

```text
/mnt/carla_assets_stage/carla_assets_0915/Carla
  -> /mnt/carla_compiled/carla/carla-0.9.15/Unreal/CarlaUE4/Content/Carla
```

Asset version:

```text
20231108_c5101a5
```

## Run Commands

Open the CARLA Unreal Editor:

```bash
/mnt/carla_compiled/scripts/launch_carla_editor.sh --detach
```

The default editor map is `Town01_Opt`, a lighter CARLA city map than
`Town10HD_Opt`. Useful map overrides:

```bash
# Fast GUI/editor sanity check
/mnt/carla_compiled/scripts/launch_carla_editor.sh --detach --map /Game/Carla/Maps/TestMaps/EmptyMap

# Small CARLA city map
/mnt/carla_compiled/scripts/launch_carla_editor.sh --detach --map Town01_Opt

# Heavy default CARLA 0.9.15 city map
/mnt/carla_compiled/scripts/launch_carla_editor.sh --detach --map Town10HD_Opt
```

`launch_carla_editor.sh` intentionally starts UE4Editor with a clean Python
environment. Do not source `env_carla_0915.sh` before launching the editor; that
environment is for CARLA PythonAPI and ScenarioRunner, and can make Unreal's
embedded Python plugin abort during startup.

The script also routes Unreal's local Derived Data Cache to:

```text
/mnt/carla_assets_stage/carla_ue_ddc
```

On Linux, UE4 reads this as `UE_LocalDataCachePath`; setting only
`UE-LocalDataCachePath` is not enough because UE normalizes hyphens to
underscores before reading environment variables.

Run ScenarioRunner:

```bash
/mnt/carla_compiled/scripts/run_scenario_runner.sh --help
```

Run environment self-check:

```bash
/mnt/carla_compiled/scripts/check_carla_0915_env.sh
```

## Current Machine Checks

Confirmed:

```text
OS: Ubuntu 20.04.6 LTS
Python: 3.8.10
GPU: NVIDIA RTX 4090
NVIDIA driver: 570.133.07
Vulkan sees: NVIDIA GeForce RTX 4090
sudo: passwordless sudo works
```

ScenarioRunner imports verified in the CARLA venv:

```text
carla
py_trees
networkx 2.2
numpy 1.18.4
shapely 1.7.1
xmlschema 1.0.18
ephem 4.2.1
srunner
```

ScenarioRunner git state:

```text
tag: v0.9.15
commit: d12d8bb Release 0.9.15 merge (#1032)
```

Note: `scenario_runner.py --help` prints `Current version: 0.9.13` because the
version string in the upstream v0.9.15 tag was not updated. The checked-out git
tag is v0.9.15.

## Local Patches

The source tree has small build-script patches because several upstream URLs or
network paths failed in 2026:

```text
Update.sh
Util/BuildTools/Setup.sh
Util/BuildTools/BuildOSM2ODR.sh
Util/BuildTools/BuildUE4Plugins.sh
Util/BuildTools/BuildCarlaUE4.sh
```

Purpose:

```text
CARLA assets URL: old S3 URL returned 403; switched to Backblaze mirror.
Boost URL: old JFrog URL returned HTML; switched to archives.boost.io and archive validation.
libpng URL: old SourceForge path returned 404; switched to older-releases path and archive validation.
OSM2ODR, StreetMap, Houdini plugin: added fixed-commit tar.gz fallback for GitHub TLS failures.
```

## Important Disk Note

The actual hardware/storage issue observed was on the external NTFS/USB project
disk, not on sudo or NVIDIA:

```text
dmesg repeatedly reports Buffer I/O error on dev sdb2, logical block 125834345.
Earlier during asset extraction, the USB disk disconnected and reappeared as /dev/sdc.
```

Current mount:

```text
/dev/sdc2 -> /mnt/carla_compiled
```

SMART through the USB bridge reports health OK, but the bridge does not expose
error counters or self-test logs. Treat the external NTFS disk/cable/enclosure
as suspect for heavy builds. Assets were moved to the internal ext4 staging
partition to reduce risk.

Avoid scanning or using this failed extraction directory:

```text
/mnt/carla_compiled/carla/carla-0.9.15/Content.broken_20260626_1826
```

Deletion attempts on 2026-06-26:

```text
rm -rf:      failed with "Directory not empty"
sudo rm -rf: failed with "Directory not empty"
ls/find:     failed with "Input/output error" while reading the directory
latest sudo rm -rf retry at 20:10 CST: failed with "Directory not empty"
```

This is not a sudo permission problem. The directory entry is unreadable on the
mounted NTFS volume. Stop using recursive scans against that path; repair the
NTFS volume offline, preferably with Windows `chkdsk /f /r`, then delete the
directory after the filesystem is clean.

## Smoke Tests

2026-06-26 19:34 CST:

```text
CARLA PythonAPI import: OK
ScenarioRunner --help: OK
UE4Editor clean-env smoke: OK to startup/resource build; stopped by timeout
UE4Editor dirty Python env smoke: failed earlier with _Py_FatalInitError
```

The clean-env UE4Editor log is:

```text
/mnt/carla_compiled/test_logs/carla_editor_smoke_ascii_clean_20260626_193417.log
```

2026-06-26 19:41 CST:

```text
/mnt/carla_compiled/scripts/launch_carla_editor.sh -nullrhi -nosound -unattended ...
Result: OK to engine initialization and Town10HD_Opt loading; stopped by forced timeout.
Log: /mnt/carla_compiled/test_logs/carla_editor_launch_script_clean_20260626_194102.log
```

2026-06-26 20:05-20:07 CST:

```text
Command:
/mnt/carla_compiled/scripts/launch_carla_editor.sh --map /Game/Carla/Maps/TestMaps/EmptyMap

Result:
Full CARLA Unreal Editor GUI opened.
Window title: CarlaUE4 - Unreal Editor
Map: EmptyMap
Log showed CARLA RPC ports 2000/2001/2002 and Rendering = Enabled.
Map check: 0 Error(s), 0 Warning(s)
Engine initialization total: 49.00 seconds
Screenshot:
/mnt/carla_compiled/test_logs/carla_editor_gui_emptymap_afterwait.png
Log:
/mnt/carla_compiled/test_logs/carla_editor_gui_emptymap_20260626_200504.log
```

2026-06-26 20:17-20:26 CST:

```text
Command:
/mnt/carla_compiled/scripts/launch_carla_editor.sh --map Town01_Opt -nosound -nop4

Result:
Full CARLA Unreal Editor GUI opened with the Town01_Opt city map.
Window title: CarlaUE4 - Unreal Editor
Map check: 0 Error(s), 0 Warning(s)
First Town01_Opt map load: 380.121 seconds
Engine initialization total: 474.09 seconds
The long wait was first-run mesh/shader/DDC compilation, not a Docker,
sudo, NVIDIA, or CARLA build failure.
Screenshot:
/mnt/carla_compiled/test_logs/carla_editor_gui_town01_afterwait3.png
Log:
/mnt/carla_compiled/test_logs/carla_editor_gui_town01_foreground_20260626_201723.log
```

2026-06-26 20:31-20:32 CST:

```text
Command:
setsid/nohup detached Town01_Opt launch, equivalent to:
/mnt/carla_compiled/scripts/launch_carla_editor.sh --detach --map Town01_Opt -nosound -nop4

Result:
Detached editor stayed open on the desktop.
Town01_Opt loaded from warmed cache in 5.603 seconds.
Engine initialization total: 52.29 seconds
The editor continued compiling remaining shaders in the background.
Screenshot:
/mnt/carla_compiled/test_logs/carla_editor_gui_town01_detached_current.png
Log:
/mnt/carla_compiled/test_logs/carla_editor_gui_town01_detached_20260626_203116.log
```
