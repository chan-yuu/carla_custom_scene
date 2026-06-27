# CARLA 0.9.15 重新编译安装计划

Updated: 2026-06-27 CST

目标：重新在一块稳定的 Linux ext4 空间里搭建 CARLA 0.9.15 source build，不使用 Docker，保留可打开 UE4Editor 的源码版工程，后续用于自定义地图、导入 XODR/FBX、编辑 Town 和运行 ScenarioRunner。

## 0. 当前磁盘状态结论

本次复核的目标目录是：

```text
/media/cyun/新加卷1/disk_4090_2
```

实际检查结果：

```text
目标目录所属设备: /dev/sda2
当前文件系统:     NTFS / fuseblk
挂载位置:         /media/cyun/新加卷1
磁盘容量:         3.8T
已用空间:         1.4T
可用空间:         2.4T
```

也就是说：

```text
/media/cyun/新加卷1/disk_4090_2 现在不是 ext4 挂载点。
它只是 /dev/sda2 这个 NTFS 盘里的一个空目录。
```

不能把一个普通 NTFS 目录直接“挂载成 ext4”。ext4 是分区或块设备级别的文件系统。要真正得到 ext4，需要以下三种方案之一：

```text
方案 A: 格式化 /dev/sda2 为 ext4
  优点: 最干净，最适合 CARLA/UE4 大量小文件、编译产物和资产缓存。
  缺点: 会清空 /dev/sda2 上当前约 1.4T 数据。必须先人工确认。

方案 B: 找另一块空闲磁盘或空闲分区，格式化成 ext4 后挂载
  优点: 不动 /dev/sda2 现有数据。
  缺点: 当前 lsblk 没看到足够大的空闲 ext4 分区。

方案 C: 在 NTFS 上创建 ext4 loop 镜像再挂载
  优点: 不格式化整盘。
  缺点: 底层仍然依赖 NTFS/USB，不能彻底解决之前 I/O 风险，不推荐给 CARLA 编译主工程。
```

之前 `Content/Carla` 的处理方式属于“挂载覆盖”，不是把原目录转换成 ext4。它的逻辑是：

```text
ext4 来源目录或 ext4 镜像
        ↓ mount / bind mount
CARLA 工程里的目标路径
```

挂载后，目标路径看起来在原工程目录里，但实际读写落在挂载来源上。目标路径本身所在的 NTFS 文件系统没有被转换。

本次已做过一个无破坏小测试：在 `/media/cyun/新加卷1/disk_4090_2` 里创建 64MB ext4 loop 镜像，挂载到测试目录，`findmnt` 显示为 ext4，并且 `chown` 后可以正常写入。测试完成后已卸载并删除临时文件。

当前只执行了不破坏数据的准备动作：创建新工作区目录、复制文档、写计划。没有格式化磁盘，没有卸载磁盘，也没有改 `/etc/fstab`。

## 1. 新工作区目录

当前已创建的新工作区：

```text
/media/cyun/新加卷1/disk_4090_2/carla_0.9.15_rebuild
```

目录规划：

```text
carla_0.9.15_rebuild/
├── carla/                 # CARLA 0.9.15 源码
├── ue/                    # CARLA fork Unreal Engine 4.26
├── scenario_runner/       # ScenarioRunner v0.9.15
├── venvs/                 # Python 3.8 虚拟环境
├── assets/                # CARLA 官方资产、导入包、中间资产
├── ddc/                   # Unreal Derived Data Cache
├── build_logs/            # 编译日志
├── test_logs/             # 启动、GUI、ScenarioRunner 测试日志
├── scripts/               # 本地辅助脚本
├── docs/                  # 全部说明文档
├── hdmap_raw/
│   ├── pointcloud/        # PCD 点云
│   └── source_hdmap/      # 原始高精地图、XODR、坐标资料
├── roadrunner/
│   ├── project/           # RoadRunner 工程
│   └── export/            # 导出的 FBX/XODR/RRDATA
├── custom_assets/
│   ├── buildings/
│   ├── fences/
│   ├── poles/
│   ├── textures/
│   └── vegetation/
├── scenarios/             # ScenarioRunner xosc/xml/routes
└── tmp/                   # 临时下载和解压目录
```

之所以把源码、UE、场景资料、资产和日志分开，是为了后续排查更清楚：

```text
源码编译问题 -> carla/、ue/、build_logs/
官方资产问题 -> assets/、ddc/
自定义地图问题 -> hdmap_raw/、roadrunner/、custom_assets/
运行测试问题 -> scenario_runner/、scenarios/、test_logs/
```

## 2. 如果确认要真正改成 ext4

重要：下面步骤会清空 `/dev/sda2`。只有在确认 `/dev/sda2` 上 1.4T 数据可以删除或已经备份后才能执行。

推荐不要把新 ext4 分区继续挂到 `/media/cyun/新加卷1/disk_4090_2`。原因是 `/media/cyun/新加卷1` 本身现在来自 `/dev/sda2`，如果格式化并卸载 `/dev/sda2`，这个父路径就不再可靠。更稳的挂载点是：

```text
/mnt/carla_4090_2
```

确认清盘后的建议命令：

```bash
sudo fuser -vm /media/cyun/新加卷1
sudo umount /media/cyun/新加卷1
sudo mkfs.ext4 -F -L carla_4090_2 /dev/sda2
sudo mkdir -p /mnt/carla_4090_2
sudo mount /dev/sda2 /mnt/carla_4090_2
sudo chown -R cyun:cyun /mnt/carla_4090_2
findmnt /mnt/carla_4090_2
df -hT /mnt/carla_4090_2
```

确认 UUID：

```bash
sudo blkid /dev/sda2
```

如果要开机自动挂载，把 UUID 写入 `/etc/fstab`：

```text
UUID=<新的-ext4-UUID> /mnt/carla_4090_2 ext4 defaults,noatime 0 2
```

然后把当前已经准备好的目录和文档迁移到真正 ext4 工作区：

```bash
mkdir -p /mnt/carla_4090_2/carla_0.9.15_rebuild
cp -a /media/cyun/新加卷1/disk_4090_2/carla_0.9.15_rebuild/. \
      /mnt/carla_4090_2/carla_0.9.15_rebuild/
```

如果不清盘，则可以继续使用当前目录做计划和资料整理，但不建议把 CARLA/UE4 主编译工程放在 NTFS 上。

## 2.1 不清盘时的折中挂载方案

如果不想清空 `/dev/sda2`，但又希望某个目录在 Linux 里表现为 ext4，可以用 ext4 loop 镜像挂载到目标目录。例如把整个新工程目录覆盖成 ext4：

```text
镜像文件:
/media/cyun/新加卷1/disk_4090_2/carla_0.9.15_rebuild.ext4.img

挂载点:
/media/cyun/新加卷1/disk_4090_2/carla_0.9.15_rebuild
```

示例命令，假设创建 500G 镜像：

```bash
cd /media/cyun/新加卷1/disk_4090_2
truncate -s 500G carla_0.9.15_rebuild.ext4.img
mkfs.ext4 -F -L carla0915_loop carla_0.9.15_rebuild.ext4.img
mkdir -p carla_0.9.15_rebuild
sudo mount -o loop carla_0.9.15_rebuild.ext4.img carla_0.9.15_rebuild
sudo chown -R cyun:cyun carla_0.9.15_rebuild
findmnt -T carla_0.9.15_rebuild
df -hT carla_0.9.15_rebuild
```

这种方式的优点：

```text
1. 不格式化 /dev/sda2。
2. 挂载点里显示 ext4。
3. Linux 权限、符号链接、大小写、小文件行为更接近真实 ext4。
4. 可以像之前 Content/Carla 那样，把 ext4 内容挂到指定目录。
```

这种方式的限制：

```text
1. 镜像文件仍然存放在 NTFS 上。
2. 如果底层 NTFS/USB 再次出现 I/O 错误，镜像也可能受影响。
3. 大镜像备份、扩容、修复都比真实 ext4 分区麻烦。
4. 不建议作为最终长期编译主盘，只适合作为不清盘前提下的折中方案。
```

如果要自动挂载 loop 镜像，可以写 `/etc/fstab`，但建议先手动跑完整个 CARLA 编译验证后再加自动挂载，避免开机挂载失败影响系统启动。

本机当前已经采用这个折中方案创建并挂载：

```text
镜像文件:
/media/cyun/新加卷1/disk_4090_2/carla_0.9.15_rebuild.ext4.img

挂载点:
/media/cyun/新加卷1/disk_4090_2/carla_0.9.15_rebuild

文件系统:
ext4

标签:
carla0915_loop

UUID:
9f60e739-2da4-4bc7-b58f-d6f44f7d15f3

逻辑大小:
150G

当前可用:
约 140G
```

复核命令：

```bash
findmnt -T /media/cyun/新加卷1/disk_4090_2/carla_0.9.15_rebuild
df -hT /media/cyun/新加卷1/disk_4090_2/carla_0.9.15_rebuild
```

重启后手动重新挂载：

```bash
/media/cyun/新加卷1/disk_4090_2/mount_carla_rebuild_ext4.sh
```

需要卸载时：

```bash
/media/cyun/新加卷1/disk_4090_2/umount_carla_rebuild_ext4.sh
```

## 3. 版本选择

固定版本：

```text
CARLA:          0.9.15 source build
Unreal Engine:  CARLA fork UE 4.26，branch: carla
ScenarioRunner: v0.9.15
Python:         3.8
Ubuntu:         20.04.6 LTS 当前最匹配
GPU:            NVIDIA RTX 4090，当前 nvidia-smi 正常
Docker:         不使用
```

选择源码版的原因：

```text
1. 需要打开 UE4Editor。
2. 需要导入和编辑自定义地图。
3. 需要放置静态资产、交通灯、材质、碰撞、语义标签。
4. 需要后续用 ScenarioRunner 在自定义 Town 上做测试。
```

## 4. 拉取源码

假设最终 ext4 工作区为：

```text
/mnt/carla_4090_2/carla_0.9.15_rebuild
```

进入目录：

```bash
cd /mnt/carla_4090_2/carla_0.9.15_rebuild
```

拉取 Unreal Engine：

```bash
mkdir -p ue
git clone --depth 1 -b carla https://github.com/CarlaUnreal/UnrealEngine.git \
  ue/UnrealEngine_4.26
```

注意：这个仓库需要 GitHub 账号已经关联 Epic Games，并有 UnrealEngine 仓库访问权限。

拉取 CARLA：

```bash
mkdir -p carla
git clone https://github.com/carla-simulator/carla.git carla/carla-0.9.15
cd carla/carla-0.9.15
git checkout 0.9.15
git submodule update --init --recursive
```

拉取 ScenarioRunner：

```bash
cd /mnt/carla_4090_2/carla_0.9.15_rebuild
mkdir -p scenario_runner
git clone https://github.com/carla-simulator/scenario_runner.git \
  scenario_runner/scenario_runner-v0.9.15
cd scenario_runner/scenario_runner-v0.9.15
git checkout v0.9.15
```

## 5. 系统依赖

Ubuntu 20.04 对 CARLA 0.9.15 最稳，使用 clang-10、lld-10、g++-7：

```bash
sudo apt-get update
sudo apt-get install -y wget software-properties-common
sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add -
sudo apt-add-repository -y "deb http://apt.llvm.org/focal/ llvm-toolchain-focal main"
sudo apt-get update

sudo apt-get install -y \
  build-essential clang-10 lld-10 g++-7 cmake ninja-build libvulkan1 \
  python python-dev python3-dev python3-pip \
  libpng-dev libtiff5-dev libjpeg-dev tzdata sed curl unzip \
  autoconf libtool rsync libxml2-dev git aria2

sudo update-alternatives --install /usr/bin/clang++ clang++ /usr/lib/llvm-10/bin/clang++ 180
sudo update-alternatives --install /usr/bin/clang clang /usr/lib/llvm-10/bin/clang 180
```

Python 侧：

```bash
python3 -m pip install --upgrade pip
pip3 install --user -Iv setuptools==47.3.1
pip3 install --user distro wheel auditwheel
```

如果系统里启用了 conda，编译 CARLA 和启动 UE4Editor 前先关闭 conda，避免 Python 库路径污染 Unreal 内嵌 Python。

## 6. 编译 Unreal Engine 4.26

```bash
cd /mnt/carla_4090_2/carla_0.9.15_rebuild/ue/UnrealEngine_4.26
./Setup.sh
./GenerateProjectFiles.sh
make
```

验证 UE4Editor 文件存在：

```bash
test -x Engine/Binaries/Linux/UE4Editor && echo "UE4Editor OK"
```

如果要单独启动空 UE4Editor：

```bash
Engine/Binaries/Linux/UE4Editor
```

## 7. 配置 CARLA 编译环境

建议创建环境文件：

```text
/mnt/carla_4090_2/carla_0.9.15_rebuild/env_carla_0915.sh
```

内容目标：

```bash
export CARLA_ROOT=/mnt/carla_4090_2/carla_0.9.15_rebuild/carla/carla-0.9.15
export UE4_ROOT=/mnt/carla_4090_2/carla_0.9.15_rebuild/ue/UnrealEngine_4.26
export SCENARIO_RUNNER_ROOT=/mnt/carla_4090_2/carla_0.9.15_rebuild/scenario_runner/scenario_runner-v0.9.15
export CARLA_EGG="$CARLA_ROOT/PythonAPI/carla/dist/carla-0.9.15-py3.8-linux-x86_64.egg"
export PYTHONPATH="$CARLA_EGG:$SCENARIO_RUNNER_ROOT:$PYTHONPATH"
```

使用方式：

```bash
source /mnt/carla_4090_2/carla_0.9.15_rebuild/env_carla_0915.sh
```

注意：这个环境用于 PythonAPI 和 ScenarioRunner。启动 UE4Editor 时应使用干净 Python 环境，避免 Unreal 的 Python 插件被外部 `PYTHONPATH` 干扰。

## 8. CARLA 资源和补丁

CARLA 0.9.15 的官方资产 ID 是：

```text
20231108_c5101a5
```

旧安装中遇到过的问题：

```text
1. 旧 S3 assets URL 返回 403。
2. Boost 旧 JFrog URL 返回 HTML。
3. libpng 旧 SourceForge 路径返回 404。
4. OSM2ODR / StreetMap / Houdini plugin 偶发 GitHub TLS 或 clone 失败。
```

因此新构建时要优先复用旧文档记录的补丁思路：

```text
Update.sh
Util/BuildTools/Setup.sh
Util/BuildTools/BuildOSM2ODR.sh
Util/BuildTools/BuildUE4Plugins.sh
Util/BuildTools/BuildCarlaUE4.sh
```

补丁目标：

```text
assets 改用 Backblaze mirror
Boost 改用 archives.boost.io
libpng 改用 SourceForge older-releases
GitHub clone 失败处增加固定 commit tar.gz fallback
下载后检查 tar 包有效性，避免 HTML 错误页被当成源码包
```

## 9. 编译 CARLA

设置环境：

```bash
cd /mnt/carla_4090_2/carla_0.9.15_rebuild/carla/carla-0.9.15
export UE4_ROOT=/mnt/carla_4090_2/carla_0.9.15_rebuild/ue/UnrealEngine_4.26
```

下载和解压官方资产：

```bash
./Update.sh
```

编译 PythonAPI：

```bash
make PythonAPI
```

编译 CARLA UE4Editor 工程：

```bash
make CarlaUE4Editor
```

也可以使用：

```bash
make launch
```

但第一次打开会很慢，因为 UE4 会编译 shader、加载资产、生成 Derived Data Cache。

## 10. UE4Editor 启动项目

CARLA 的 UE4 项目是：

```text
/mnt/carla_4090_2/carla_0.9.15_rebuild/carla/carla-0.9.15/Unreal/CarlaUE4/CarlaUE4.uproject
```

UE4Editor 实际启动的是这个 `.uproject`。

推荐启动脚本放在：

```text
/mnt/carla_4090_2/carla_0.9.15_rebuild/scripts/launch_carla_editor.sh
```

启动时应设置：

```bash
export UE_LocalDataCachePath=/mnt/carla_4090_2/carla_0.9.15_rebuild/ddc
```

示例命令：

```bash
/mnt/carla_4090_2/carla_0.9.15_rebuild/ue/UnrealEngine_4.26/Engine/Binaries/Linux/UE4Editor \
  /mnt/carla_4090_2/carla_0.9.15_rebuild/carla/carla-0.9.15/Unreal/CarlaUE4/CarlaUE4.uproject \
  /Game/Carla/Maps/Town01_Opt \
  -nosound -nop4
```

轻量 GUI 验证地图：

```text
/Game/Carla/Maps/TestMaps/EmptyMap
```

常用官方地图：

```text
Town01_Opt
Town10HD_Opt
```

验证标准：

```text
1. UE4Editor 窗口打开。
2. CarlaUE4 项目加载成功。
3. 能打开 Town01_Opt 或 EmptyMap。
4. 不出现 Python 插件 abort。
5. 不出现 Content/Carla 缺失导致的大量红色报错。
6. Play 后 Python client 能连接 localhost:2000。
```

## 11. ScenarioRunner 配置

创建 Python 3.8 虚拟环境：

```bash
python3 -m venv /mnt/carla_4090_2/carla_0.9.15_rebuild/venvs/carla0915-py38
source /mnt/carla_4090_2/carla_0.9.15_rebuild/venvs/carla0915-py38/bin/activate
python -m pip install --upgrade pip
```

安装 ScenarioRunner 依赖时要贴近 0.9.15：

```bash
cd /mnt/carla_4090_2/carla_0.9.15_rebuild/scenario_runner/scenario_runner-v0.9.15
python -m pip install -r requirements.txt
```

验证导入：

```bash
python - <<'PY'
import carla
import py_trees
import networkx
import numpy
import shapely
import xmlschema
import srunner
print("ScenarioRunner imports OK")
PY
```

## 12. 自定义地图导入流程

最小输入：

```text
TianjinRoad.xodr
TianjinRoad.fbx
```

PCD 点云不能直接作为 CARLA 可运行地图。点云主要用于重建道路、对齐建筑和检查几何。CARLA 真正需要：

```text
XODR: 道路逻辑、车道、junction、waypoint、交通规则
FBX:  可见道路、地面、路肩、人行道和静态几何
```

导入目录示例：

```text
/mnt/carla_4090_2/carla_0.9.15_rebuild/carla/carla-0.9.15/Import/TianjinRoadPackage
├── TianjinRoadPackage.json
└── TianjinRoad
    ├── TianjinRoad.fbx
    └── TianjinRoad.xodr
```

JSON 示例：

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

导入：

```bash
cd /mnt/carla_4090_2/carla_0.9.15_rebuild/carla/carla-0.9.15
make import ARGS="--package=TianjinRoadPackage"
```

然后用 UE4Editor 打开：

```bash
UE4Editor CarlaUE4.uproject /Game/TianjinRoadPackage/Maps/TianjinRoad -nosound -nop4
```

UE4 中继续处理：

```text
材质
碰撞
语义标签
交通灯 actor 和 trigger volume
路牌
spawn points
行人导航 mesh / pedestrian nav bin
建筑、围墙、杆件、植被等静态资产
```

## 13. 打包地图包含什么

一个 CARLA 官方或自定义打包地图通常包含：

```text
Map umap:        地图主关卡
OpenDRIVE xodr:  道路逻辑
Mesh:            道路、地面、建筑、静态物体
Materials:       材质实例、贴图
Collision:       可行驶区域、障碍物碰撞
Semantic tags:   语义分割类别
Traffic lights:  信号灯 actor、灯组、trigger
Traffic signs:   限速、停车、让行等标志
Nav data:         行人导航数据，可选但常用
Package config:  导入和打包描述文件
```

例如官方 `Town01_Opt` 不只是一个地图文件，它依赖 CARLA Content 目录下的大量共享资产、材质、蓝图、交通灯和 OpenDRIVE 数据。

## 14. 验收清单

磁盘：

```text
findmnt 显示工作区在 ext4 上
df -hT 显示足够可用空间
当前用户对工作区有读写权限
```

源码：

```text
UE4 branch 为 carla
CARLA checkout 为 0.9.15
ScenarioRunner checkout 为 v0.9.15
```

编译：

```text
UE4Editor 可执行文件存在
make PythonAPI 成功
make CarlaUE4Editor 成功
CARLA egg/wheel 生成
libUE4Editor-CarlaUE4.so 生成
libUE4Editor-Carla.so 生成
```

GUI：

```text
EmptyMap 可打开
Town01_Opt 可打开
Play 后 server 监听 2000 端口
Python client 可连接并读取 world/map
```

自定义地图：

```text
XODR 能被 CARLA 加载
FBX 和 XODR 坐标对齐
地图中车辆 spawn points 可用
交通灯 trigger 可用
ScenarioRunner 能在新地图运行最小场景
```

## 15. 开始前需要人工确认

在真正重建前需要先确认一件事：

```text
是否允许清空 /dev/sda2 当前约 1.4T 数据，并把它格式化为 ext4？
```

如果允许，下一步就是执行 ext4 格式化和挂载，然后把新工作区迁移到 `/mnt/carla_4090_2/carla_0.9.15_rebuild`。

如果不允许，就需要换一块空盘或空分区。否则继续在 NTFS 上重编译 CARLA/UE4，很可能重复之前外置盘 I/O 错误和坏目录问题。
