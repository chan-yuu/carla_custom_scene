# CARLA 0.9.15 本机编译安装过程说明

Updated: 2026-06-26 20:45 CST

这份文档记录本机这套 CARLA 0.9.15 source build 的搭建过程：目录为什么这样放、资源怎么拉取、哪些脚本做了补丁、按什么顺序编译，以及最后怎么验证 CARLA + UE4 图形界面。

## 目标

本次目标不是安装 Docker 版，也不是跑官方预编译包，而是在本机直接编译并运行：

```text
CARLA: 0.9.15 source build
Unreal Engine: CARLA fork UE 4.26
ScenarioRunner: v0.9.15
Python: 3.8
GPU: NVIDIA RTX 4090
OS: Ubuntu 20.04.6 LTS
```

选择 source build 的原因是后续要做自定义 Town，需要打开 Unreal Editor 编辑地图、资产、材质、碰撞、交通灯、导航等内容。预编译包适合直接跑现成 Town，不适合完整编辑自定义地图。

## 目录决策

原始工程目录在外置 NTFS 盘上：

```text
/media/cyun/新加卷/disk_4090/carla_compiled
```

实际命令统一使用 ASCII 路径：

```text
/mnt/carla_compiled
```

这样做有两个原因：

```text
1. UE4/CARLA 的部分构建脚本、日志和第三方工具对非 ASCII 路径更脆弱。
2. 命令、脚本、日志引用更短，更容易复现和排查。
```

当前主要目录如下：

```text
/mnt/carla_compiled
├── carla/carla-0.9.15                      # CARLA 0.9.15 源码
├── ue/UnrealEngine_4.26                    # CARLA fork Unreal Engine 4.26
├── scenario_runner/scenario_runner-v0.9.15 # ScenarioRunner v0.9.15
├── venvs/carla0915-py38                    # Python 3.8 虚拟环境
├── scripts                                 # 本地辅助脚本
├── docs                                    # 本地文档
└── test_logs                               # 测试和启动日志
```

外置 NTFS 盘在重资产解压时出现过 I/O 错误，所以 CARLA 官方资产和 UE Derived Data Cache 没有继续放在 NTFS 上，而是放到内置 ext4 分区：

```text
/mnt/carla_assets_stage/carla_assets_0915/Carla # CARLA Content/Carla 资产
/mnt/carla_assets_stage/carla_ue_ddc            # UE Derived Data Cache
```

资产通过 bind mount 挂到 CARLA 工程里：

```text
/mnt/carla_assets_stage/carla_assets_0915/Carla
  -> /mnt/carla_compiled/carla/carla-0.9.15/Unreal/CarlaUE4/Content/Carla
```

这个设计的结果是：源码和工程还在原项目盘，重读写的资产缓存走 ext4，减少 NTFS/USB 盘风险。

## 资源拉取

本地有一个辅助脚本：

```bash
/mnt/carla_compiled/scripts/bootstrap_sources.sh
```

它做的事情等价于：

```bash
mkdir -p /mnt/carla_compiled/{carla,ue,scenario_runner}

git clone --depth 1 -b carla https://github.com/CarlaUnreal/UnrealEngine.git \
  /mnt/carla_compiled/ue/UnrealEngine_4.26

git clone https://github.com/carla-simulator/carla.git \
  /mnt/carla_compiled/carla/carla-0.9.15
cd /mnt/carla_compiled/carla/carla-0.9.15
git checkout 0.9.15
git submodule update --init --recursive

git clone https://github.com/carla-simulator/scenario_runner.git \
  /mnt/carla_compiled/scenario_runner/scenario_runner-v0.9.15
cd /mnt/carla_compiled/scenario_runner/scenario_runner-v0.9.15
git checkout v0.9.15
```

当前本地版本：

```text
CARLA source commit:        d7b45c1
Unreal Engine source commit: e9d9e60c8
ScenarioRunner commit:      d12d8bb
ScenarioRunner tag:         v0.9.15
```

CARLA 资产版本来自 `Util/ContentVersions.txt`：

```text
0.9.15 / Latest: 20231108_c5101a5
```

## 系统依赖

依赖安装脚本：

```bash
/mnt/carla_compiled/scripts/root_fix_and_install_deps_ubuntu2004.sh
```

它主要做了这些事：

```text
1. 修正 /usr/bin/sudo 和 /usr/bin/su 的 owner/mode。
2. 添加 Ubuntu toolchain PPA。
3. 添加 apt.llvm.org 的 Ubuntu 20.04 clang 工具链源。
4. 安装 CARLA 0.9.15 source build 需要的编译依赖。
5. 设置 clang-10 / clang++-10 alternatives。
6. 安装 Python 构建依赖。
```

关键依赖包括：

```text
build-essential clang-10 lld-10 g++-7 cmake ninja-build libvulkan1
python python-dev python3-dev python3-pip
libpng-dev libtiff5-dev libjpeg-dev
autoconf libtool rsync libxml2-dev git aria2
```

## Unreal Engine 编译

UE4 必须先编译，因为 CARLA 后续 C++、插件、地图工程都会依赖 `UE4_ROOT`。

实际路径：

```text
/mnt/carla_compiled/ue/UnrealEngine_4.26
```

编译顺序：

```bash
cd /mnt/carla_compiled/ue/UnrealEngine_4.26
./Setup.sh
./GenerateProjectFiles.sh
make
```

`Setup.sh` 会下载 UE 第三方依赖；`GenerateProjectFiles.sh` 生成项目文件；`make` 编译 UE4Editor。

验证点：

```text
/mnt/carla_compiled/ue/UnrealEngine_4.26/Engine/Binaries/Linux/UE4Editor
```

## CARLA 源码补丁

CARLA 0.9.15 发布较早，2026 年重新编译时遇到了一些上游 URL 失效或 TLS/下载问题，所以对少数构建脚本做了本地补丁。

涉及文件：

```text
carla/carla-0.9.15/Update.sh
carla/carla-0.9.15/Util/BuildTools/Setup.sh
carla/carla-0.9.15/Util/BuildTools/BuildOSM2ODR.sh
carla/carla-0.9.15/Util/BuildTools/BuildUE4Plugins.sh
carla/carla-0.9.15/Util/BuildTools/BuildCarlaUE4.sh
```

补丁目的：

```text
CARLA assets:
  旧 S3 链接返回 403，改到 Backblaze mirror:
  https://carla-assets.s3.us-east-005.backblazeb2.com/${CONTENT_ID}.tar.gz

Boost:
  旧 JFrog 链接返回 HTML，改到:
  https://archives.boost.io/release/${BOOST_VERSION}/source/
  并加 tar 包有效性检查。

libpng:
  旧 SourceForge 路径返回 404，改到 older-releases 路径。

OSM2ODR:
  GitHub clone 失败时，增加固定 commit tar.gz fallback。

StreetMap UE4 plugin:
  GitHub clone 失败时，增加固定 commit tar.gz fallback。

Houdini Engine plugin:
  GitHub clone 失败时，增加固定 commit tar.gz fallback。
```

这些补丁不改变 CARLA 运行逻辑，只是让旧版本依赖在当前网络环境下能稳定下载和构建。

## CARLA 资产处理

官方流程是：

```bash
cd /mnt/carla_compiled/carla/carla-0.9.15
./Update.sh
```

但是本机外置 NTFS 盘在资产解压过程中出现过 I/O 错误，留下了坏目录：

```text
/mnt/carla_compiled/carla/carla-0.9.15/Content.broken_20260626_1826
```

该目录多次删除失败：

```text
rm -rf:      Directory not empty
sudo rm -rf: Directory not empty
ls/find:     Input/output error
```

因此实际处理方式改成：

```text
1. 在内置 ext4 分区 /mnt/carla_assets_stage 解压 CARLA 资产。
2. 确认资产版本为 20231108_c5101a5。
3. 将 /mnt/carla_assets_stage/carla_assets_0915/Carla bind mount 到
   Unreal/CarlaUE4/Content/Carla。
4. 避免再递归扫描或使用 Content.broken_20260626_1826。
```

当前资产挂载检查：

```bash
findmnt /mnt/carla_compiled/carla/carla-0.9.15/Unreal/CarlaUE4/Content/Carla
```

## CARLA 编译顺序

进入工程前先设置环境：

```bash
cd /mnt/carla_compiled
source /mnt/carla_compiled/env_carla_0915.sh
```

环境文件主要设置：

```text
CARLA_PROJECT_ROOT=/mnt/carla_compiled
CARLA_ROOT=/mnt/carla_compiled/carla/carla-0.9.15
UE4_ROOT=/mnt/carla_compiled/ue/UnrealEngine_4.26
SCENARIO_RUNNER_ROOT=/mnt/carla_compiled/scenario_runner/scenario_runner-v0.9.15
CARLA_PY38_VENV=/mnt/carla_compiled/venvs/carla0915-py38
```

构建 CARLA PythonAPI：

```bash
cd /mnt/carla_compiled/carla/carla-0.9.15
make PythonAPI
```

产物：

```text
/mnt/carla_compiled/carla/carla-0.9.15/PythonAPI/carla/dist/carla-0.9.15-py3.8-linux-x86_64.egg
/mnt/carla_compiled/carla/carla-0.9.15/PythonAPI/carla/dist/carla-0.9.15-cp38-cp38-linux_x86_64.whl
```

构建 CARLA Unreal Editor 工程：

```bash
cd /mnt/carla_compiled/carla/carla-0.9.15
make CarlaUE4Editor
```

产物：

```text
/mnt/carla_compiled/carla/carla-0.9.15/Unreal/CarlaUE4/Binaries/Linux/libUE4Editor-CarlaUE4.so
/mnt/carla_compiled/carla/carla-0.9.15/Unreal/CarlaUE4/Plugins/Carla/Binaries/Linux/libUE4Editor-Carla.so
/mnt/carla_compiled/carla/carla-0.9.15/Unreal/CarlaUE4/Plugins/CarlaTools/Binaries/Linux/libUE4Editor-CarlaTools.so
/mnt/carla_compiled/carla/carla-0.9.15/Unreal/CarlaUE4/Plugins/Streetmap/Binaries/Linux/libUE4Editor-StreetMapRuntime.so
```

## ScenarioRunner 配置

ScenarioRunner 使用 v0.9.15 tag：

```text
/mnt/carla_compiled/scenario_runner/scenario_runner-v0.9.15
```

运行入口：

```bash
/mnt/carla_compiled/scripts/run_scenario_runner.sh --help
```

本地验证过的 Python import：

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

注意：上游 v0.9.15 tag 中 `scenario_runner.py --help` 打印的版本字符串仍可能显示 `0.9.13`，但 git tag 是 `v0.9.15`。

## UE4Editor 启动脚本

直接用 `make launch` 会受当前 shell Python 环境影响，尤其 source 过 CARLA PythonAPI/ScenarioRunner 环境后，UE 内嵌 Python 插件可能启动失败。之前观察到过 `_Py_FatalInitError`。

因此增加了专门的启动脚本：

```bash
/mnt/carla_compiled/scripts/launch_carla_editor.sh
```

它做了这些事：

```text
1. 使用固定 CARLA_ROOT 和 UE4_ROOT。
2. 默认打开较轻的 Town01_Opt，而不是很重的 Town10HD_Opt。
3. 支持 --map 指定地图。
4. 清理 PYTHONHOME / PYTHONPATH / VIRTUAL_ENV / CONDA_*，避免污染 UE 内嵌 Python。
5. 强制使用 Vulkan。
6. 设置 UE Derived Data Cache 到 /mnt/carla_assets_stage/carla_ue_ddc。
7. 支持 --detach，用 setsid/nohup 让 UE4Editor 窗口脱离当前终端。
```

Linux 下 UE4 会把环境变量名里的 `-` 转成 `_` 再读取，所以脚本同时设置了：

```text
UE_LocalDataCachePath=/mnt/carla_assets_stage/carla_ue_ddc
UE-LocalDataCachePath=/mnt/carla_assets_stage/carla_ue_ddc
```

实际生效的是 `UE_LocalDataCachePath`。验证日志中应出现：

```text
LogDerivedDataCache: Using Local data cache path /mnt/carla_assets_stage/carla_ue_ddc: Writable
```

推荐启动命令：

```bash
# 默认 Town01_Opt
/mnt/carla_compiled/scripts/launch_carla_editor.sh --detach

# 快速 GUI 检查
/mnt/carla_compiled/scripts/launch_carla_editor.sh --detach --map /Game/Carla/Maps/TestMaps/EmptyMap

# 小城市地图
/mnt/carla_compiled/scripts/launch_carla_editor.sh --detach --map Town01_Opt -nosound -nop4

# 重地图
/mnt/carla_compiled/scripts/launch_carla_editor.sh --detach --map Town10HD_Opt -nosound -nop4
```

## 验证过程

环境自检：

```bash
/mnt/carla_compiled/scripts/check_carla_0915_env.sh
```

验证内容包括：

```text
系统版本、磁盘、挂载点、内存
git/cmake/ninja/make/clang/g++/python/pip/curl/wget/rsync
nvidia-smi
CARLA/UE/ScenarioRunner 路径
资产版本和 bind mount
Python egg
UE 插件 .so 产物
Python imports
```

PythonAPI 和 ScenarioRunner 验证：

```bash
source /mnt/carla_compiled/env_carla_0915.sh
python3 -c "import carla; print(carla)"
/mnt/carla_compiled/scripts/run_scenario_runner.sh --help
```

UE4Editor headless smoke test 用过 `-nullrhi -nosound -unattended`，它只能验证引擎初始化，不会显示图形窗口。之前没看到 CARLA+UE4 画面，部分原因就是测试参数故意是 headless。

GUI 验证顺序：

```text
1. EmptyMap:
   用轻量地图确认 UE4Editor GUI、CARLA 插件、Vulkan、X11 都能工作。

2. Town01_Opt:
   用小城市地图确认真正 CARLA 城市地图能进入 Unreal Editor。

3. Town10HD_Opt:
   作为重地图保留，不作为第一次启动默认值。
```

已记录结果：

```text
EmptyMap:
  窗口: CarlaUE4 - Unreal Editor
  Map check: 0 Error(s), 0 Warning(s)
  Engine initialization: 49.00 seconds

Town01_Opt first run:
  窗口: CarlaUE4 - Unreal Editor
  Map check: 0 Error(s), 0 Warning(s)
  Loading map 'Town01_Opt': 380.121 seconds
  Engine initialization: 474.09 seconds

Town01_Opt warmed cache:
  Loading map 'Town01_Opt': 5.603 seconds
  Engine initialization: 52.29 seconds
```

截图和日志在：

```text
/mnt/carla_compiled/test_logs/carla_editor_gui_emptymap_afterwait.png
/mnt/carla_compiled/test_logs/carla_editor_gui_town01_afterwait3.png
/mnt/carla_compiled/test_logs/carla_editor_gui_town01_detached_current.png
```

## 关键判断和问题处理

### 为什么不用 Docker

本机已经可以直接编译并运行 UE4Editor，`sudo` 可用，NVIDIA 驱动和 Vulkan 也可用。Docker 对当前目标没有必要，反而会增加 X11、GPU、文件挂载和 UE GUI 调试复杂度。

### 为什么一开始没看到完整 CARLA 城市画面

原因有三层：

```text
1. 一些早期 smoke test 使用了 -nullrhi / -unattended，本来就不会开图形画面。
2. 默认 Town10HD_Opt 很重，首次加载会长时间构建 shader/mesh/DDC。
3. Town01_Opt 首次加载也需要几分钟；等待完成后已经进入完整 CarlaUE4 - Unreal Editor。
```

### NVIDIA 是否损坏

没有。主机侧 `nvidia-smi` 正常，UE4Editor Vulkan 日志识别到 RTX 4090。之前的显示/设备问题不是驱动损坏结论。

### DDC 为什么要改

最初 UE 日志使用的是：

```text
../../../Engine/DerivedDataCache
```

并且 Boot cache 只有 512 MB。脚本设置 `UE-LocalDataCachePath` 后，Linux UE4 实际没有读到，因为 UE 会把环境变量名中的 `-` 转成 `_`。修正后设置 `UE_LocalDataCachePath`，日志确认切到了：

```text
/mnt/carla_assets_stage/carla_ue_ddc
```

### 坏资产目录如何处理

坏目录：

```text
/mnt/carla_compiled/carla/carla-0.9.15/Content.broken_20260626_1826
```

这不是权限问题，`sudo rm -rf` 也删不掉。原因是外置 NTFS 文件系统目录项 I/O 错误。不要继续递归扫描它。建议离线修复 NTFS，优先在 Windows 下执行：

```text
chkdsk /f /r
```

文件系统修复后再删除该目录。

## 当前继续工作的入口

日常进入环境：

```bash
cd /mnt/carla_compiled
source /mnt/carla_compiled/env_carla_0915.sh
```

启动 CARLA UE4 Editor：

```bash
/mnt/carla_compiled/scripts/launch_carla_editor.sh --detach --map Town01_Opt -nosound -nop4
```

运行 ScenarioRunner：

```bash
/mnt/carla_compiled/scripts/run_scenario_runner.sh --help
```

查看状态总结：

```text
/mnt/carla_compiled/docs/local_install_status.md
```

本过程文档：

```text
/mnt/carla_compiled/docs/local_build_process.md
```
