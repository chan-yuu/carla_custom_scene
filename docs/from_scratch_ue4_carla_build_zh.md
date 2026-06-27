# 从零下载并编译 UE4 + CARLA 0.9.15

更新时间：2026-06-28 CST

本文给出一套可以自己重新尝试的完整命令流程。它不要求复用当前已经编译好的目录。

当前已验证工作区仍然是：

```text
/mnt/carla_latest
```

如果只是想重新练习一遍，建议用一个新的目录，避免破坏当前可用环境：

```bash
export CARLA_LAB=/mnt/carla_from_scratch
```

如果你想直接在当前 overlay 里重新做，也可以把 `CARLA_LAB` 改成：

```bash
export CARLA_LAB=/mnt/carla_latest
```

## RoadRunner 是否有 Linux 版、是否免费

结论：

```text
1. RoadRunner 有 Linux 版。
2. 当前 MathWorks 官方系统要求页面列出 Linux 支持 Ubuntu 20.04 和 22.04。
3. RoadRunner 不是免费开源软件。
4. MathWorks 官网提供 Request a trial / Get pricing / Request a quote 入口。
5. 学校或单位可能有许可证，但是否包含 RoadRunner 要看具体授权。
```

官方页面：

```text
RoadRunner 系统要求:
https://www.mathworks.com/help/roadrunner/ug/roadrunner-system-requirements.html

RoadRunner 产品页:
https://www.mathworks.com/products/roadrunner.html

RoadRunner 平台与产品要求:
https://www.mathworks.com/support/requirements/roadrunner.html
```

CARLA 自建地图不强制必须用 RoadRunner。RoadRunner 的优势是能比较方便地同时导出：

```text
<MapName>.fbx
<MapName>.xodr
<MapName>.rrdata.xml
```

如果不用 RoadRunner，也可以用其他 CAD/GIS/建模工具生成道路 mesh，再自己准备 OpenDRIVE `.xodr`。关键是最终仍然要有对齐的 `FBX + XODR`。

## 推荐系统

推荐：

```text
Ubuntu 20.04
NVIDIA 独显
NVIDIA 驱动和 Vulkan 可用
至少 200 GB 空间，实际更建议 300 GB+
```

原因：

```text
1. CARLA 0.9.15 官方 Linux 编译文档给 Ubuntu 20.04 使用 clang-10/lld-10/g++-7。
2. CARLA 0.9.15 使用 CARLA fork 的 UE 4.26。
3. CARLA 构建脚本会使用 UE4 自带的 clang-10.0.1 centos7 toolchain。
4. Ubuntu 22.04/24.04 可能能编，但常需要 Python、clang、OpenSSL、Boost、libpng 等兼容性修补。
```

本文命令按 Ubuntu 20.04 写。Ubuntu 22.04/24.04 不建议作为第一次从零编译环境。

## 0. 准备 GitHub/Epic 权限

UE4 源码不是普通公开下载。你必须先完成：

```text
1. 注册 Epic Games / Unreal Engine 账号
2. 注册 GitHub 账号
3. 在 Epic 账号里关联 GitHub
4. 接受 EpicGames GitHub organization 邀请
```

否则下面这个仓库可能会 clone 失败，表现为 404 或无权限：

```text
https://github.com/CarlaUnreal/UnrealEngine.git
```

测试：

```bash
git ls-remote https://github.com/CarlaUnreal/UnrealEngine.git >/dev/null
echo $?
```

返回 `0` 才表示当前 GitHub 权限和网络基本可用。

## 1. 准备目录

如果使用当前硬盘 overlay，先挂载：

```bash
/media/cyun/新加卷1/disk_4090_2/mount_carla.sh
```

创建一个新的练习目录：

```bash
export CARLA_LAB=/mnt/carla_from_scratch

mkdir -p "$CARLA_LAB"/{ue,carla,scenario_runner,venvs,logs}
cd "$CARLA_LAB"
```

后续路径：

```text
UE4:            $CARLA_LAB/ue/UnrealEngine_4.26
CARLA:          $CARLA_LAB/carla/carla-0.9.15
ScenarioRunner: $CARLA_LAB/scenario_runner/scenario_runner-v0.9.15
Python venv:    $CARLA_LAB/venvs/carla0915-py38
```

## 2. 安装系统依赖

Ubuntu 20.04：

```bash
sudo apt-get update
sudo apt-get install -y wget curl git gnupg ca-certificates software-properties-common

sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add -
sudo apt-add-repository -y "deb http://apt.llvm.org/focal/ llvm-toolchain-focal main"

sudo apt-get update
sudo apt-get install -y \
  build-essential clang-10 lld-10 g++-7 cmake ninja-build \
  libvulkan1 vulkan-tools mesa-utils \
  python python-dev python3-dev python3-pip python3-venv \
  libpng-dev libtiff5-dev libjpeg-dev libxml2-dev \
  tzdata sed unzip autoconf libtool rsync aria2 xdg-user-dirs \
  libomp-dev
```

设置默认 clang：

```bash
sudo update-alternatives --install /usr/bin/clang++ clang++ /usr/lib/llvm-10/bin/clang++ 180
sudo update-alternatives --install /usr/bin/clang clang /usr/lib/llvm-10/bin/clang 180

clang --version
clang++ --version
```

检查 NVIDIA/Vulkan：

```bash
nvidia-smi || true
vulkaninfo --summary || true
```

如果机器同时看到 NVIDIA 和 Mesa llvmpipe，启动 UE4/CARLA 时建议加：

```bash
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json
```

## 3. 下载并编译 UE4

下载 CARLA fork 的 UE4.26：

```bash
export CARLA_LAB=/mnt/carla_from_scratch

git clone --depth 1 -b carla https://github.com/CarlaUnreal/UnrealEngine.git \
  "$CARLA_LAB/ue/UnrealEngine_4.26"
```

编译：

```bash
cd "$CARLA_LAB/ue/UnrealEngine_4.26"

./Setup.sh
./GenerateProjectFiles.sh
make -j"$(nproc)"
```

预期产物：

```text
$CARLA_LAB/ue/UnrealEngine_4.26/Engine/Binaries/Linux/UE4Editor
$CARLA_LAB/ue/UnrealEngine_4.26/Engine/Binaries/Linux/UE4Editor-Cmd
```

验证 UE4 能启动：

```bash
cd "$CARLA_LAB/ue/UnrealEngine_4.26"

VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json \
Engine/Binaries/Linux/UE4Editor \
  -vulkan -nop4
```

如果只是命令行确认文件存在：

```bash
test -x "$CARLA_LAB/ue/UnrealEngine_4.26/Engine/Binaries/Linux/UE4Editor" && echo "UE4Editor OK"
```

## 4. 下载 CARLA 0.9.15 源码

```bash
export CARLA_LAB=/mnt/carla_from_scratch

git clone https://github.com/carla-simulator/carla.git \
  "$CARLA_LAB/carla/carla-0.9.15"

cd "$CARLA_LAB/carla/carla-0.9.15"
git checkout 0.9.15
git submodule update --init --recursive
```

确认版本：

```bash
git describe --tags --always
git status --short
```

## 5. 下载 CARLA Content 资源

使用 CARLA 原本官方脚本：

```bash
cd "$CARLA_LAB/carla/carla-0.9.15"
./Update.sh
```

CARLA 0.9.15 的 Content 版本从这里读取：

```text
$CARLA_LAB/carla/carla-0.9.15/Util/ContentVersions.txt
```

资源最终应在：

```text
$CARLA_LAB/carla/carla-0.9.15/Unreal/CarlaUE4/Content/Carla
```

检查：

```bash
test -d "$CARLA_LAB/carla/carla-0.9.15/Unreal/CarlaUE4/Content/Carla" && echo "Content dir OK"
du -sh "$CARLA_LAB/carla/carla-0.9.15/Unreal/CarlaUE4/Content/Carla"
find "$CARLA_LAB/carla/carla-0.9.15/Unreal/CarlaUE4/Content/Carla/Maps" -maxdepth 2 -type f -name '*.umap' | head
```

如果网络下载失败，优先重复执行 `./Update.sh`。不要手动把错误或不完整 tar 包塞进 Content。

## 6. 下载 ScenarioRunner

```bash
export CARLA_LAB=/mnt/carla_from_scratch

git clone https://github.com/carla-simulator/scenario_runner.git \
  "$CARLA_LAB/scenario_runner/scenario_runner-v0.9.15"

cd "$CARLA_LAB/scenario_runner/scenario_runner-v0.9.15"
git checkout v0.9.15
```

## 7. 准备 Python 3.8 venv

Ubuntu 20.04 默认 Python3 通常是 3.8：

```bash
python3 --version
```

创建 venv：

```bash
export CARLA_LAB=/mnt/carla_from_scratch

python3 -m venv "$CARLA_LAB/venvs/carla0915-py38"
source "$CARLA_LAB/venvs/carla0915-py38/bin/activate"

python -m pip install --upgrade pip
python -m pip install -Iv setuptools==47.3.1 wheel distro auditwheel
```

安装 ScenarioRunner/CARLA 0.9.15 兼容依赖：

```bash
python -m pip install -r "$CARLA_LAB/scenario_runner/scenario_runner-v0.9.15/requirements.txt"

python -m pip install \
  py_trees==0.8.3 \
  numpy==1.18.4 \
  networkx==2.2 \
  Shapely==1.7.1 \
  xmlschema==1.0.18 \
  ephem \
  pygame \
  opencv-python==4.2.0.32
```

注意：

```text
不要把 open3d 装进这个主 venv。
当前较新的 open3d wheel 会拉高 numpy，容易破坏 CARLA 0.9.15/ScenarioRunner 需要的旧依赖组合。
如果需要 open3d，单独建另一个 venv。
```

## 8. 编译 CARLA

设置环境变量：

```bash
export CARLA_LAB=/mnt/carla_from_scratch
export UE4_ROOT="$CARLA_LAB/ue/UnrealEngine_4.26"
export CARLA_ROOT="$CARLA_LAB/carla/carla-0.9.15"
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json

source "$CARLA_LAB/venvs/carla0915-py38/bin/activate"
cd "$CARLA_ROOT"
```

先让 CARLA 准备依赖：

```bash
make -j"$(nproc)" setup
```

编译 PythonAPI：

```bash
make -j"$(nproc)" PythonAPI
```

编译 CARLA UE4 Editor 目标：

```bash
make -j"$(nproc)" CarlaUE4Editor
```

或者用官方常见流程直接 build 并 launch：

```bash
make -j"$(nproc)" launch
```

为了排错更清楚，第一次建议按 `setup -> PythonAPI -> CarlaUE4Editor -> 手动启动 UE4Editor` 分步跑。

预期产物：

```text
$CARLA_ROOT/PythonAPI/carla/dist/carla-0.9.15-py3.8-linux-x86_64.egg
$CARLA_ROOT/PythonAPI/carla/dist/carla-0.9.15-cp38-cp38-linux_x86_64.whl
$CARLA_ROOT/Unreal/CarlaUE4/Binaries/Linux/libUE4Editor-CarlaUE4.so
$CARLA_ROOT/Unreal/CarlaUE4/Plugins/Carla/Binaries/Linux/libUE4Editor-Carla.so
```

检查：

```bash
ls -lh "$CARLA_ROOT"/PythonAPI/carla/dist/
ls -lh "$CARLA_ROOT"/Unreal/CarlaUE4/Binaries/Linux/
ls -lh "$CARLA_ROOT"/Unreal/CarlaUE4/Plugins/Carla/Binaries/Linux/
```

## 9. 安装/使用 CARLA PythonAPI

方式 A：安装 wheel 到 venv：

```bash
source "$CARLA_LAB/venvs/carla0915-py38/bin/activate"
python -m pip install --force-reinstall "$CARLA_ROOT"/PythonAPI/carla/dist/carla-0.9.15-cp38-cp38-linux_x86_64.whl
python -c "import carla; print(carla.__file__)"
```

方式 B：不安装 wheel，直接用 egg：

```bash
source "$CARLA_LAB/venvs/carla0915-py38/bin/activate"

export PYTHONPATH="$CARLA_ROOT/PythonAPI/carla:$PYTHONPATH"
export PYTHONPATH="$(find "$CARLA_ROOT/PythonAPI/carla/dist" -name 'carla-0.9.15-py3.*-linux-x86_64.egg' | sort | head -n 1):$PYTHONPATH"

python -c "import carla; print(carla.__file__)"
```

ScenarioRunner：

```bash
export PYTHONPATH="$CARLA_LAB/scenario_runner/scenario_runner-v0.9.15:$PYTHONPATH"
python -c "import srunner; print(srunner.__file__)"
```

## 10. 启动 CARLA Editor

启动项目，不直接加载地图：

```bash
export CARLA_LAB=/mnt/carla_from_scratch
export UE4_ROOT="$CARLA_LAB/ue/UnrealEngine_4.26"
export CARLA_ROOT="$CARLA_LAB/carla/carla-0.9.15"

VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json \
"$UE4_ROOT/Engine/Binaries/Linux/UE4Editor" \
  "$CARLA_ROOT/Unreal/CarlaUE4/CarlaUE4.uproject" \
  -vulkan -nosound -nop4 -preferNvidia
```

启动并直接加载 Town01_Opt：

```bash
VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json \
"$UE4_ROOT/Engine/Binaries/Linux/UE4Editor" \
  "$CARLA_ROOT/Unreal/CarlaUE4/CarlaUE4.uproject" \
  /Game/Carla/Maps/Town01_Opt \
  -vulkan -nosound -nop4 -preferNvidia
```

第一次打开会很慢，因为 UE4 会生成 shader 和 DerivedDataCache。只要正常退出，下次会快很多。

## 11. 如果出现 BuildingMaster 导入错误

如果启动 Town01_Opt 时出现类似：

```text
Failed import for BoolProperty ... BuildingMaster ... BuildingSpawnableItems
```

可定向重编译/重存这两个 Blueprint：

```bash
cd "$CARLA_ROOT/Unreal/CarlaUE4"

mkdir -p Saved
printf '%s\n' \
'/Game/Carla/Blueprints/LevelDesign/BuildingSpawnableItems.BuildingSpawnableItems' \
'/Game/Carla/Blueprints/LevelDesign/BuildingMaster.BuildingMaster' \
> Saved/BlueprintCompileWhitelist.txt
```

定向编译：

```bash
VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json \
"$UE4_ROOT/Engine/Binaries/Linux/UE4Editor-Cmd" \
  "$CARLA_ROOT/Unreal/CarlaUE4/CarlaUE4.uproject" \
  -run=CompileAllBlueprints \
  -WhitelistFile=Saved/BlueprintCompileWhitelist.txt \
  -SimpleAssetList -unattended -nop4 -nosound -nullrhi -stdout
```

定向重存：

```bash
VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json \
"$UE4_ROOT/Engine/Binaries/Linux/UE4Editor-Cmd" \
  "$CARLA_ROOT/Unreal/CarlaUE4/CarlaUE4.uproject" \
  -run=ResavePackages \
  -PACKAGE=/Game/Carla/Blueprints/LevelDesign/BuildingSpawnableItems \
  -PACKAGE=/Game/Carla/Blueprints/LevelDesign/BuildingMaster \
  -ProjectOnly -SkipMapCheck -unattended -nop4 -nosound -nullrhi -stdout
```

成功输出应包含：

```text
2/2 packages were resaved
Success - 0 error(s)
```

## 12. 验证 PythonAPI 连接

先在 UE4 Editor 里按 Play，或使用已启动的 CARLA server。

另开终端：

```bash
export CARLA_LAB=/mnt/carla_from_scratch
export CARLA_ROOT="$CARLA_LAB/carla/carla-0.9.15"

source "$CARLA_LAB/venvs/carla0915-py38/bin/activate"
export PYTHONPATH="$CARLA_LAB/scenario_runner/scenario_runner-v0.9.15:$PYTHONPATH"
export PYTHONPATH="$CARLA_ROOT/PythonAPI/carla:$PYTHONPATH"
export PYTHONPATH="$(find "$CARLA_ROOT/PythonAPI/carla/dist" -name 'carla-0.9.15-py3.*-linux-x86_64.egg' | sort | head -n 1):$PYTHONPATH"
```

检查连接：

```bash
python - <<'PY'
import carla
client = carla.Client("127.0.0.1", 2000)
client.set_timeout(10.0)
world = client.get_world()
print("map:", world.get_map().name)
print("actors:", len(world.get_actors()))
PY
```

跑示例：

```bash
cd "$CARLA_ROOT/PythonAPI/examples"
python generate_traffic.py --number-of-vehicles 20 --number-of-walkers 20
```

ScenarioRunner：

```bash
cd "$CARLA_LAB/scenario_runner/scenario_runner-v0.9.15"
python scenario_runner.py --help
```

## 13. 可选：打包 CARLA

如果要生成可分发的 LinuxNoEditor 包：

```bash
export UE4_ROOT="$CARLA_LAB/ue/UnrealEngine_4.26"
export CARLA_ROOT="$CARLA_LAB/carla/carla-0.9.15"
cd "$CARLA_ROOT"

make -j"$(nproc)" package
```

产物通常在：

```text
$CARLA_ROOT/Dist/
```

包很大，不要提交到源码仓库。

## 14. 重新构建常用命令

```bash
cd "$CARLA_ROOT"

make help
make -j"$(nproc)" PythonAPI
make -j"$(nproc)" CarlaUE4Editor
make -j"$(nproc)" launch
make -j"$(nproc)" package
```

清理命令要谨慎：

```bash
make clean
```

它会删除大量构建产物，下次需要重新编译。

## 15. 不要提交到远程的内容

从零编译会产生大量大文件。顶层源码/文档仓库不应该提交这些：

```text
ue/
carla/
scenario_runner/
venvs/
downloads/
Dist/
Build/
DerivedDataCache/
Saved/
Intermediate/
Binaries/
*.tar.gz
*.zip
*.fbx
*.obj
*.bin
*.uasset
*.umap
*.egg
*.whl
```

适合提交的只有：

```text
docs/*.md
README.md
小型脚本源码
小型 JSON 模板
```

当前顶层仓库 `.gitignore` 已经默认忽略大目录，只放行 README 和 docs。

## 16. 最短命令总览

下面是压缩版，适合确认顺序：

```bash
export CARLA_LAB=/mnt/carla_from_scratch
mkdir -p "$CARLA_LAB"/{ue,carla,scenario_runner,venvs,logs}

git clone --depth 1 -b carla https://github.com/CarlaUnreal/UnrealEngine.git \
  "$CARLA_LAB/ue/UnrealEngine_4.26"
cd "$CARLA_LAB/ue/UnrealEngine_4.26"
./Setup.sh
./GenerateProjectFiles.sh
make -j"$(nproc)"

git clone https://github.com/carla-simulator/carla.git \
  "$CARLA_LAB/carla/carla-0.9.15"
cd "$CARLA_LAB/carla/carla-0.9.15"
git checkout 0.9.15
git submodule update --init --recursive
./Update.sh

git clone https://github.com/carla-simulator/scenario_runner.git \
  "$CARLA_LAB/scenario_runner/scenario_runner-v0.9.15"
cd "$CARLA_LAB/scenario_runner/scenario_runner-v0.9.15"
git checkout v0.9.15

python3 -m venv "$CARLA_LAB/venvs/carla0915-py38"
source "$CARLA_LAB/venvs/carla0915-py38/bin/activate"
python -m pip install --upgrade pip
python -m pip install -Iv setuptools==47.3.1 wheel distro auditwheel
python -m pip install -r "$CARLA_LAB/scenario_runner/scenario_runner-v0.9.15/requirements.txt"

export UE4_ROOT="$CARLA_LAB/ue/UnrealEngine_4.26"
export CARLA_ROOT="$CARLA_LAB/carla/carla-0.9.15"
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json
cd "$CARLA_ROOT"

make -j"$(nproc)" setup
make -j"$(nproc)" PythonAPI
make -j"$(nproc)" CarlaUE4Editor

VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json \
"$UE4_ROOT/Engine/Binaries/Linux/UE4Editor" \
  "$CARLA_ROOT/Unreal/CarlaUE4/CarlaUE4.uproject" \
  /Game/Carla/Maps/Town01_Opt \
  -vulkan -nosound -nop4 -preferNvidia
```
