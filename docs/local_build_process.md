# CARLA 0.9.15 Manual Build Commands

Updated: 2026-06-28 CST

This workspace keeps CARLA, UE4, ScenarioRunner, venvs, and custom-map files
under one overlay:

```text
/mnt/carla_latest
```

For a longer Chinese guide that starts from an empty directory, including
RoadRunner notes, UE4 download/build, CARLA download/build, Content download,
ScenarioRunner, PythonAPI, launch, and validation commands, see:

```text
docs/from_scratch_ue4_carla_build_zh.md
```

Mount first:

```bash
/media/cyun/新加卷1/disk_4090_2/mount_carla.sh
cd /mnt/carla_latest
```

## Versions

```text
CARLA:          0.9.15
Unreal Engine:  CARLA fork UE 4.26, branch carla
ScenarioRunner: v0.9.15
Python:         3.8
Recommended OS: Ubuntu 20.04
```

Ubuntu 20.04 is recommended because CARLA 0.9.15 documents a 20.04 dependency
set using `clang-10`, `lld-10`, `g++-7`, Python development headers, and
UE4.26's bundled `v17_clang-10.0.1-centos7` toolchain. Ubuntu 22.04/24.04 may
need compatibility fixes or a rebuild.

## Install Dependencies

```bash
sudo apt-get update
sudo apt-get install -y \
  build-essential clang-10 lld-10 g++-7 cmake ninja-build libvulkan1 \
  python python-dev python3-dev python3-pip python3-venv \
  libpng-dev libtiff5-dev libjpeg-dev tzdata sed curl unzip \
  autoconf libtool rsync libxml2-dev git aria2 wget \
  software-properties-common gnupg ca-certificates xdg-user-dirs

sudo update-alternatives --install /usr/bin/clang++ clang++ /usr/lib/llvm-10/bin/clang++ 180
sudo update-alternatives --install /usr/bin/clang clang /usr/lib/llvm-10/bin/clang 180
```

## Source Paths

```text
UE4:            /mnt/carla_latest/ue/UnrealEngine_4.26
CARLA:          /mnt/carla_latest/carla/carla-0.9.15
ScenarioRunner: /mnt/carla_latest/scenario_runner/scenario_runner-v0.9.15
Python venv:    /mnt/carla_latest/venvs/carla0915-py38
CARLA assets:   /mnt/carla_latest/carla/carla-0.9.15/Unreal/CarlaUE4/Content/Carla
```

No top-level `assets/`, `patches/`, `ddc/`, `scripts/`, `build_logs/`, or
`test_logs/` directory is required for installation. UE/CARLA may recreate
cache/log directories when launched.

## Download Sources

```bash
mkdir -p /mnt/carla_latest/{ue,carla,scenario_runner,venvs}

git clone --depth 1 -b carla https://github.com/CarlaUnreal/UnrealEngine.git \
  /mnt/carla_latest/ue/UnrealEngine_4.26

git clone https://github.com/carla-simulator/carla.git \
  /mnt/carla_latest/carla/carla-0.9.15
cd /mnt/carla_latest/carla/carla-0.9.15
git checkout 0.9.15
git submodule update --init --recursive

git clone https://github.com/carla-simulator/scenario_runner.git \
  /mnt/carla_latest/scenario_runner/scenario_runner-v0.9.15
cd /mnt/carla_latest/scenario_runner/scenario_runner-v0.9.15
git checkout v0.9.15
```

## Build UE4

UE4 has already been built in the current workspace. To rebuild:

```bash
cd /mnt/carla_latest/ue/UnrealEngine_4.26
./Setup.sh
./GenerateProjectFiles.sh
make -j"$(nproc)"
```

Expected binary:

```text
/mnt/carla_latest/ue/UnrealEngine_4.26/Engine/Binaries/Linux/UE4Editor
```

## Launch UE4 Only

This starts UE4Editor without opening CARLA:

```bash
cd /mnt/carla_latest/ue/UnrealEngine_4.26
Engine/Binaries/Linux/UE4Editor -vulkan -nop4
```

If Python environment variables cause embedded Python issues, launch with:

```bash
env -u PYTHONHOME -u PYTHONPATH -u VIRTUAL_ENV -u CONDA_PREFIX -u CONDA_DEFAULT_ENV \
  /mnt/carla_latest/ue/UnrealEngine_4.26/Engine/Binaries/Linux/UE4Editor \
  -vulkan -nop4
```

## Download CARLA Assets

Use CARLA's original official downloader:

```bash
cd /mnt/carla_latest/carla/carla-0.9.15
./Update.sh
```

For CARLA 0.9.15, the asset version is read from:

```text
/mnt/carla_latest/carla/carla-0.9.15/Util/ContentVersions.txt
```

and the assets are extracted to:

```text
/mnt/carla_latest/carla/carla-0.9.15/Unreal/CarlaUE4/Content/Carla
```

## Python Environment

```bash
python3 -m venv /mnt/carla_latest/venvs/carla0915-py38
source /mnt/carla_latest/venvs/carla0915-py38/bin/activate
python -m pip install --upgrade pip
python -m pip install -Iv setuptools==47.3.1 wheel distro auditwheel
python -m pip install -r /mnt/carla_latest/scenario_runner/scenario_runner-v0.9.15/requirements.txt
python -m pip install py_trees networkx==2.2 numpy==1.18.4 shapely==1.7.1 xmlschema==1.0.18 ephem
```

## Build CARLA

```bash
export UE4_ROOT=/mnt/carla_latest/ue/UnrealEngine_4.26
export CARLA_ROOT=/mnt/carla_latest/carla/carla-0.9.15

source /mnt/carla_latest/venvs/carla0915-py38/bin/activate
cd "$CARLA_ROOT"

make -j"$(nproc)" PythonAPI
make -j"$(nproc)" CarlaUE4Editor
```

Expected outputs:

```text
/mnt/carla_latest/carla/carla-0.9.15/PythonAPI/carla/dist/carla-0.9.15-py3.8-linux-x86_64.egg
/mnt/carla_latest/carla/carla-0.9.15/PythonAPI/carla/dist/carla-0.9.15-cp38-cp38-linux_x86_64.whl
/mnt/carla_latest/carla/carla-0.9.15/Unreal/CarlaUE4/Binaries/Linux/libUE4Editor-CarlaUE4.so
/mnt/carla_latest/carla/carla-0.9.15/Unreal/CarlaUE4/Plugins/Carla/Binaries/Linux/libUE4Editor-Carla.so
```

## Launch CARLA Editor

After assets and CARLA plugins are built:

```bash
/mnt/carla_latest/ue/UnrealEngine_4.26/Engine/Binaries/Linux/UE4Editor \
  /mnt/carla_latest/carla/carla-0.9.15/Unreal/CarlaUE4/CarlaUE4.uproject \
  /Game/Carla/Maps/Town01_Opt \
  -vulkan -nosound -nop4
```

## ScenarioRunner

After PythonAPI is built:

```bash
source /mnt/carla_latest/venvs/carla0915-py38/bin/activate
export PYTHONPATH=/mnt/carla_latest/scenario_runner/scenario_runner-v0.9.15:/mnt/carla_latest/carla/carla-0.9.15/PythonAPI/carla:$PYTHONPATH
export PYTHONPATH="$(find /mnt/carla_latest/carla/carla-0.9.15/PythonAPI/carla/dist -name 'carla-0.9.15-py3.*-linux-x86_64.egg' | sort | head -n 1):$PYTHONPATH"

cd /mnt/carla_latest/scenario_runner/scenario_runner-v0.9.15
python scenario_runner.py --help
```

The upstream v0.9.15 tag may still print an older internal version string in
help output; trust the git tag and path.
