# CARLA 0.9.15 自定义天津道路 Town 制作计划

本文档面向一个目标：使用 CARLA 0.9.15 源码版，把天津某一段道路的高精地图制作成一个可运行的自定义 Town；道路、建筑、围墙、路灯、交通灯等静态内容放入地图；ScenarioRunner 只负责测试事件、车辆、行人、障碍物和评价逻辑。

参考版本固定为：

```text
CARLA: 0.9.15 source build
Unreal Engine: CARLA fork UE 4.26
ScenarioRunner: v0.9.15
OS 推荐: Ubuntu 20.04；Ubuntu 22.04 可尝试，但遇到依赖问题概率更高
Python 推荐: 3.8，和 Ubuntu 20.04 默认环境一致
```

## 1. 总体判断

### 为什么使用源码版，而不是预编译包

你的需求不是“跑现成 Town”，而是“导入自己的道路并在 Unreal Editor 里继续编辑静态场景”。官方自定义地图流程区分了 packaged 版本和 source build 版本：预编译包可以导入地图，但不能用 Unreal Editor 做完整自定义；源码版可以用 `make import` 导入 `.fbx` + `.xodr`，再进入 Unreal Editor 放建筑、围墙、交通灯、标志、植被等。因此这里应使用源码版。

### Town 和 ScenarioRunner 的边界

```text
Town / Map:
  静态世界。道路、车道线、路口、红绿灯、标志、建筑、围墙、护栏、路灯、树、人行道、停车区、永久障碍物。

ScenarioRunner:
  测试过程。ego 车、NPC 车、行人、临时障碍物、触发条件、路线、超时、碰撞/到达/闯红灯等评价指标。
```

不要把“每个测试场景会变化的东西”都做进地图。建议：

```text
固定建筑、围墙、道路、红绿灯杆、路灯、长期隔离栏 -> Unreal 地图
测试用车辆、行人、锥桶、临时施工牌、静态障碍物 -> ScenarioRunner
```

## 2. 最终工作流

```text
天津高精地图 / 点云 / 航拍 / CAD / OSM
        ↓
坐标系整理、地图原点选择、道路拓扑清洗
        ↓
RoadRunner 或其他工具生成道路
        ↓
TianjinRoad.xodr + TianjinRoad.fbx
        ↓
CARLA 0.9.15 源码版 make import
        ↓
Unreal Editor 补静态环境
        ↓
检查 OpenDRIVE 拓扑、spawn points、traffic light trigger、collision、semantic tags
        ↓
生成 pedestrian navigation .bin
        ↓
make package，可选
        ↓
ScenarioRunner v0.9.15 在 TianjinRoad 上运行场景
```

## 3. 需要准备的东西

### 软件

```text
Ubuntu 20.04，推荐
NVIDIA 驱动 + Vulkan
git / cmake / ninja / clang-10 / lld-10 / g++-7
Python 3.8 + pip
CARLA fork Unreal Engine 4.26
CARLA 0.9.15 源码
CARLA 0.9.15 assets
ScenarioRunner v0.9.15
RoadRunner，推荐；没有 RoadRunner 时需要其他能导出 OpenDRIVE + FBX 的工具
Blender，可选，用于修资产、缩放、碰撞、原点、材质
```

### 硬件

官方 0.9.15 Linux build 文档给出的基本量级是约 130 GB 磁盘空间、至少 6 GB 显存、推荐 8 GB 或更高。实际做自定义地图时建议预留更多：

```text
磁盘: 200 GB 以上更稳
内存: 32 GB 推荐，16 GB 可尝试但编译/UE 编辑会吃紧
显存: 8 GB 推荐
CPU: 编译越多核越省时间
```

### 地图与资产

最小必须项：

```text
TianjinRoad.xodr  # OpenDRIVE，道路逻辑和拓扑
TianjinRoad.fbx   # 道路可视化几何
道路材质
碰撞设置
交通灯 / 标志 / 停止线
建筑 / 围墙 / 护栏 / 路灯 / 树等静态资产
```

高精地图中最好能拿到：

```text
车道中心线 / 车道边界
车道宽度
车道类型: driving, sidewalk, shoulder, parking
车道线类型: 实线、虚线、双黄线
路口连接关系: predecessor, successor, junction connection
红绿灯、停止线、限速牌、让行/停车标志
人行横道
高程、坡度、超高，可选但推荐
坐标系说明，例如 CGCS2000 / WGS84 / UTM / 本地 ENU
```

## 4. 目录建议

可以把工程组织成下面这样，避免 CARLA 源码目录里混入原始数据：

```text
carla_tianjin_project/
├── carla/
│   └── carla-0.9.15-source/
├── ue/
│   └── UnrealEngine_4.26/
├── scenario_runner/
│   └── scenario_runner-v0.9.15/
├── hdmap_raw/
│   ├── source_hdmap/
│   ├── pointcloud/
│   └── coordinate_system.md
├── roadrunner/
│   ├── TianjinRoad.rrscene
│   └── export/
│       ├── TianjinRoad.fbx
│       ├── TianjinRoad.xodr
│       └── TianjinRoad.rrdata.xml
├── custom_assets/
│   ├── buildings/
│   ├── fences/
│   ├── poles/
│   ├── vegetation/
│   └── textures/
├── scenarios/
│   ├── Tianjin_StaticObstacle.xosc
│   ├── Tianjin_FollowVehicle.xml
│   └── routes_tianjin.xml
└── docs/
    ├── import_log.md
    ├── known_issues.md
    └── validation_checklist.md
```

## 5. 安装和编译 CARLA 0.9.15

### 5.1 安装系统依赖

Ubuntu 20.04 推荐使用官方 0.9.15 文档中的 clang-10 工具链：

```bash
sudo apt-get update
sudo apt-get install -y wget software-properties-common
sudo add-apt-repository ppa:ubuntu-toolchain-r/test
wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add -
sudo apt-add-repository "deb http://apt.llvm.org/focal/ llvm-toolchain-focal main"
sudo apt-get update

sudo apt-get install -y \
  build-essential clang-10 lld-10 g++-7 cmake ninja-build libvulkan1 \
  python python-dev python3-dev python3-pip \
  libpng-dev libtiff5-dev libjpeg-dev tzdata sed curl unzip \
  autoconf libtool rsync libxml2-dev git aria2

sudo update-alternatives --install /usr/bin/clang++ clang++ /usr/lib/llvm-10/bin/clang++ 180
sudo update-alternatives --install /usr/bin/clang clang /usr/lib/llvm-10/bin/clang 180
```

Python 构建依赖：

```bash
python3 -m pip install --upgrade pip
pip3 install --user -Iv setuptools==47.3.1
pip3 install --user distro wheel auditwheel
```

注意：如果系统里有 conda，编译和运行 ScenarioRunner 时先关闭 conda，避免 Python 包和系统库冲突。

### 5.2 编译 CARLA fork Unreal Engine 4.26

需要 GitHub 账号已关联 Epic Games，否则无法克隆 UnrealEngine 私有仓库。

```bash
git clone --depth 1 -b carla https://github.com/CarlaUnreal/UnrealEngine.git ~/UnrealEngine_4.26
cd ~/UnrealEngine_4.26
./Setup.sh
./GenerateProjectFiles.sh
make
```

验证 UE4Editor：

```bash
cd ~/UnrealEngine_4.26/Engine/Binaries/Linux
./UE4Editor
```

### 5.3 获取 CARLA 0.9.15 源码

```bash
mkdir -p ~/carla_build
cd ~/carla_build
git clone https://github.com/carla-simulator/carla.git carla-0.9.15
cd carla-0.9.15
git checkout 0.9.15
git submodule update --init --recursive
```

设置 UE4 路径：

```bash
export UE4_ROOT=~/UnrealEngine_4.26
```

建议写入 `~/.bashrc` 或 `~/.zshrc`：

```bash
export UE4_ROOT=$HOME/UnrealEngine_4.26
```

### 5.4 下载 0.9.15 对应资产

优先使用：

```bash
cd ~/carla_build/carla-0.9.15
./Update.sh
```

如果下载失败，查看：

```bash
less Util/ContentVersions.txt
```

找到 0.9.15 对应 assets 地址，手动下载后解压到：

```text
Unreal/CarlaUE4/Content/Carla
```

### 5.5 编译 PythonAPI 和启动 Editor

```bash
cd ~/carla_build/carla-0.9.15
make PythonAPI
make launch
```

第一次 `make launch` 会很久。Unreal Editor 打开后按 `Play`，另开终端验证 Python API：

```bash
cd ~/carla_build/carla-0.9.15/PythonAPI/examples
python3 -m pip install -r requirements.txt
python3 generate_traffic.py
```

如果 FPS 很低，Unreal Editor 里关闭：

```text
Edit -> Editor Preferences -> Performance -> Use Less CPU when in Background
```

## 6. 从高精地图制作 OpenDRIVE + FBX

### 6.1 坐标系和地图原点

高精地图通常是大地坐标或投影坐标。CARLA/Unreal 更适合局部坐标，建议：

```text
选天津道路段附近一个基准点作为 local origin
将经纬度 / 投影坐标转换到本地 ENU
让地图主体尽量靠近 (0, 0, 0)
单位统一为米
记录 origin 的经纬度、高程、投影参数
```

`coordinate_system.md` 至少记录：

```text
source CRS:
target local origin:
x axis direction:
y axis direction:
z / elevation source:
scale:
known offsets:
```

地图离原点太远会导致 Unreal 浮点精度问题，也会让导入后难以查看。

### 6.2 RoadRunner 建路原则

官方推荐 RoadRunner 生成 CARLA 所需 `.fbx` 和 `.xodr`。建议 RoadRunner 里只做道路骨架和必要道路元素：

```text
道路中心线 / 车道线
路口
人行道
斑马线
停止线
交通灯逻辑位置
基础路面材质
```

不建议一开始在 RoadRunner 里放大量建筑、树、灯杆和围墙。大量 props 会显著拖慢 Unreal 导入；这些更适合导入 CARLA 后在 Unreal Editor 里用 CARLA 的蓝图工具补。

RoadRunner 导出前必须检查：

```text
地图中心接近 (0,0)
OpenDRIVE Preview 正常
junction connection 正常
lane direction 正常
predecessor / successor 正常
车道宽度和道路边界无明显穿插
停止线和信号灯关联合理
```

如果 OpenDRIVE Preview 显示 junction 错误，先在 RoadRunner 里修，必要时使用 Maneuver Tool / Rebuild Maneuver Roads。

### 6.3 RoadRunner 导出设置

使用：

```text
File -> Export -> CARLA (.fbx, .xodr, .rrdata.xml)
```

建议勾选：

```text
Split by Segmentation
Power of Two Texture Dimensions
Embed Textures
Export to Tiles，地图较大时使用
```

一般不要勾选：

```text
Export Individual Tiles
```

导出结果至少包含：

```text
TianjinRoad.fbx
TianjinRoad.xodr
TianjinRoad.rrdata.xml
```

关键要求：`.fbx` 和 `.xodr` 的 `<mapName>` 必须完全一致，例如：

```text
TianjinRoad.fbx
TianjinRoad.xodr
```

不要一个叫 `tianjin_road.fbx`，另一个叫 `TianjinRoad.xodr`。

## 7. 导入 CARLA 源码版

### 7.1 make import

```bash
cd ~/carla_build/carla-0.9.15
mkdir -p Import
cp ~/carla_tianjin_project/roadrunner/export/TianjinRoad.fbx Import/
cp ~/carla_tianjin_project/roadrunner/export/TianjinRoad.xodr Import/

make import ARGS="--package=TianjinRoadPackage"
```

导入后会生成类似目录：

```text
Unreal/CarlaUE4/Content/TianjinRoadPackage/
├── Config/
├── Maps/
├── Static/
├── OpenDrive/
└── Nav/
```

随后打开 Editor：

```bash
make launch
```

在 Unreal Editor 里打开你的 `TianjinRoad` map。

### 7.2 如果只想快速验证 xodr

可以先使用 OpenDRIVE standalone mode，不做最终地图，只检查道路拓扑：

```bash
cd ~/carla_build/carla-0.9.15
make launch
```

按 `Play` 后另开终端：

```bash
cd ~/carla_build/carla-0.9.15/PythonAPI/util
python3 config.py -x /path/to/TianjinRoad.xodr
```

这会由 `.xodr` 临时生成道路 mesh，适合检查：

```text
CARLA 能否解析 xodr
waypoint 是否连续
junction 是否正常
spawn point 是否合理
ScenarioRunner 坐标是否落在路网上
```

它不适合作为最终效果，因为周围环境基本为空。

## 8. Unreal Editor 中制作静态场景

### 8.1 静态环境的资产来源

优先级建议：

```text
1. CARLA 自带资产: Content/Carla/Static, Content/Carla/Blueprints
2. CARLA 程序化建筑和样条蓝图
3. RoadRunner 少量必要道路资产
4. Blender 自制资产
5. Sketchfab / TurboSquid / 其他模型库，注意授权
6. NVIDIA Omniverse SimReady，0.9.15 引入支持，但先作为可选补充
```

### 8.2 建筑

快速搭建不需要真实还原每栋楼。用程序化建筑即可：

```text
Content/Carla/Blueprints/LevelDesign/BP_Procedural_Building
```

操作：

```text
拖入场景
设置 Num Floors
设置 Length X / Length Y
选择 Base / Body / Top / Roof mesh
设置 doors / walls
点击 Create Building 或启用 Create Automatically
```

建议：

```text
近处建筑用更高细节
远处建筑用简单 block
道路两侧先形成空间边界，不要过早追求真实贴图
```

### 8.3 围墙、护栏、路灯、电线杆

使用 CARLA 的 spline 类蓝图：

```text
Content/Carla/Blueprints/LevelDesign/BP_Wall
Content/Carla/Blueprints/LevelDesign/BP_Spline
Content/Carla/Blueprints/LevelDesign/BP_RepSpline
Content/Carla/Static/Pole/PoweLine/BP_SplinePoweLine
```

用途：

```text
BP_Wall: 连续围墙、护栏
BP_Spline: 沿曲线连续铺设的 mesh
BP_RepSpline: 路灯、树、杆件等按间距重复放置
BP_SplinePoweLine: 电线杆和电线
```

这些资产要检查 collision，尤其是围墙、护栏、隔离栏。

### 8.4 交通灯和交通标志

交通灯路径：

```text
Content/Carla/Static/TrafficLight/StreetLights_01
```

交通标志路径：

```text
Content/Carla/Static/TrafficSign
```

交通灯步骤：

```text
1. 拖入交通灯蓝图
2. 对准路口实际位置
3. 选择 BoxTrigger，调整 trigger volume 到对应车道
4. 路口处拖入 BP_TrafficLightGroup
5. 把同一组路口交通灯加入 Traffic Lights 数组
6. timing 后续通过 Python API 配置
```

注意：只放一个红绿灯模型是不够的。车辆和 Traffic Manager 感知交通灯依赖 trigger volume 和 OpenDRIVE/地图信号配置。

### 8.5 道路材质、贴花和细节

建议先保证道路逻辑，再做视觉：

```text
沥青材质
车道线材质
人行道材质
井盖、裂缝、补丁、落叶等 decal
路缘石和排水沟
```

感知仿真要注意语义分割标签，尽量把资产放进正确分类目录，例如：

```text
Road
Sidewalks
Buildings
Fences
Poles
TrafficSigns
Vegetation
```

### 8.6 Collision 检查

至少检查：

```text
道路 surface 有 collision
人行道和路缘石有 collision
墙、护栏、建筑、隔离栏有 collision
不该碰撞的视觉贴花没有多余 collision
车辆不会掉出地图
车辆不会在路口 invisible wall 上卡住
```

Unreal 中可打开 collision view，必要时对 static mesh 设置：

```text
Collision Complexity -> Use Complex Collision As Simple
```

这适合复杂静态几何，但不要无脑对所有资产使用，复杂 collision 会影响性能。

## 9. 生成行人导航

如果要让行人能 spawn 和导航，必须生成 pedestrian navigation `.bin`。应在地图静态环境基本完成后生成，否则建筑、围墙、花坛等后来添加的障碍物可能挡住行人路径。

### 9.1 mesh 命名要求

CARLA 识别可行走区域依赖 mesh 名称：

```text
Sidewalk: Road_Sidewalk 或 Roads_Sidewalk
Crosswalk: Road_Crosswalk 或 Roads_Crosswalk
Grass: Road_Grass 或 Roads_Grass
Road: Road_Road / Roads_Road / Road_Curb / Roads_Curb / Road_Gutter / Road_Marking
```

### 9.2 导出并生成 nav

Unreal Editor 中：

```text
1. 给 BP_Sky 和不参与行人导航的大型 mesh 添加 NoExport tag
2. 检查 sidewalk / crosswalk / grass 命名
3. Ctrl + A 选择场景
4. File -> Carla Exporter
5. 得到 Unreal/CarlaUE4/Saved/TianjinRoad.obj
```

Linux 生成：

```bash
cd ~/carla_build/carla-0.9.15
cp Unreal/CarlaUE4/Saved/TianjinRoad.obj Util/DockerUtils/dist/
cp Unreal/CarlaUE4/Content/TianjinRoadPackage/OpenDrive/TianjinRoad.xodr Util/DockerUtils/dist/

cd Util/DockerUtils/dist
./build.sh TianjinRoad
```

得到：

```text
TianjinRoad.bin
```

放回：

```text
Unreal/CarlaUE4/Content/TianjinRoadPackage/Nav/TianjinRoad.bin
```

验证：

```bash
cd ~/carla_build/carla-0.9.15/PythonAPI/examples
python3 generate_traffic.py --walkers 30 --vehicles 0
```

## 10. 安装 ScenarioRunner v0.9.15

ScenarioRunner 必须和 CARLA 版本匹配。CARLA 0.9.15 使用 ScenarioRunner `v0.9.15`。

```bash
cd ~/carla_build
git clone https://github.com/carla-simulator/scenario_runner.git scenario_runner-v0.9.15
cd scenario_runner-v0.9.15
git checkout v0.9.15
pip3 install --user -r requirements.txt
```

设置环境变量：

```bash
export CARLA_ROOT=~/carla_build/carla-0.9.15
export SCENARIO_RUNNER_ROOT=~/carla_build/scenario_runner-v0.9.15
export PYTHONPATH=$PYTHONPATH:${CARLA_ROOT}/PythonAPI/carla/dist/carla-0.9.15-py3.8-linux-x86_64.egg
export PYTHONPATH=$PYTHONPATH:${CARLA_ROOT}/PythonAPI/carla
```

实际 egg 名称用下面命令确认：

```bash
ls ~/carla_build/carla-0.9.15/PythonAPI/carla/dist/
```

建议把环境变量写成脚本，例如 `env_carla_0915.sh`：

```bash
#!/usr/bin/env bash
export CARLA_ROOT=$HOME/carla_build/carla-0.9.15
export SCENARIO_RUNNER_ROOT=$HOME/carla_build/scenario_runner-v0.9.15
export UE4_ROOT=$HOME/UnrealEngine_4.26
export PYTHONPATH=$PYTHONPATH:$CARLA_ROOT/PythonAPI/carla
export PYTHONPATH=$PYTHONPATH:$(ls $CARLA_ROOT/PythonAPI/carla/dist/carla-0.9.15-py3.*-linux-x86_64.egg | head -n 1)
```

使用：

```bash
source ~/env_carla_0915.sh
```

先跑官方例子：

```bash
cd ~/carla_build/carla-0.9.15
make launch
```

Unreal Editor 按 `Play`，另开终端：

```bash
source ~/env_carla_0915.sh
cd ~/carla_build/scenario_runner-v0.9.15
python3 scenario_runner.py --scenario FollowLeadingVehicle_1 --reloadWorld
```

如果报 `No module named agents`，通常是 `PYTHONPATH` 缺少：

```text
${CARLA_ROOT}/PythonAPI/carla
```

## 11. 在自定义 Town 上运行 ScenarioRunner

### 11.1 先确认 Town 能被 CARLA 加载

启动 CARLA 后：

```bash
cd ~/carla_build/carla-0.9.15/PythonAPI/util
python3 config.py --map TianjinRoad
```

或 Python 检查：

```python
import carla

client = carla.Client("127.0.0.1", 2000)
client.set_timeout(10.0)
world = client.load_world("TianjinRoad")
print(world.get_map().name)
print(len(world.get_map().get_spawn_points()))
```

`get_spawn_points()` 不应为 0。如果为 0，先检查 OpenDRIVE 和 map package 配置。

### 11.2 场景坐标

ScenarioRunner 里 actor 坐标必须是 CARLA 世界坐标，不是原始高精地图经纬度。建议写一个辅助脚本从当前地图点击/采样坐标，或根据 local ENU origin 做转换。

基本原则：

```text
OpenDRIVE / RoadRunner / Unreal / ScenarioRunner 使用同一局部坐标
不要直接把经纬度填进 scenario
所有 actor 的 z 值略高于地面，例如 0.3-0.8
yaw 和道路方向一致
```

### 11.3 OpenSCENARIO 示例

最小 `.xosc` 可以定义 ego、初始位置、天气、停止条件。自定义地图关键在 `Town` 或运行命令加载地图时指定。实际字段要参考 ScenarioRunner v0.9.15 examples。

运行：

```bash
cd ~/carla_build/scenario_runner-v0.9.15
python3 scenario_runner.py \
  --openscenario ~/carla_tianjin_project/scenarios/Tianjin_StaticObstacle.xosc \
  --reloadWorld
```

### 11.4 Python scenario 示例方向

如果场景逻辑复杂，建议写 Python scenario。优点：

```text
可以复用 CARLA API
可以查询 waypoint
可以动态 spawn actor
可以写更复杂的触发和评价
```

目录通常涉及：

```text
scenario_runner/srunner/scenarios/
scenario_runner/srunner/examples/
```

先复制一个接近的官方 scenario，再改：

```text
FollowLeadingVehicle
ControlLoss
ObjectCrashVehicle
DynamicObjectCrossing
```

## 12. 最小里程碑

### 阶段 0：环境跑通

验收标准：

```text
make PythonAPI 成功
make launch 成功
UE Editor 能 Play
PythonAPI examples/generate_traffic.py 能连接
ScenarioRunner v0.9.15 官方 FollowLeadingVehicle_1 能跑
```

### 阶段 1：200 米直路 demo

目的：打通 RoadRunner -> CARLA import -> UE -> ScenarioRunner 全链路。

```text
RoadRunner 画 200m 直路
导出 DemoRoad.fbx + DemoRoad.xodr
make import ARGS="--package=DemoRoadPackage"
UE 里打开 DemoRoad
确认车辆可 spawn
ScenarioRunner 放一个 ego 和一个静态障碍物
```

不要跳过这个阶段。它能提前暴露环境、路径、命名、版本和导入问题。

### 阶段 2：天津一个真实路口

目的：验证高精地图到 OpenDRIVE 的拓扑质量。

```text
选 1 个十字或丁字路口
车道、转向关系、停止线、斑马线、红绿灯做准确
周边只放低精建筑盒子和围墙
测试 Traffic Manager / waypoint / ScenarioRunner 车辆是否能通过路口
```

### 阶段 3：补静态环境

目的：达到“看起来像真实城市道路段”的静态场景。

```text
程序化建筑
围墙、护栏、隔离栏
路灯、电线杆、交通杆
植被、公交站、停车车辆
道路贴花和材质细节
collision 和 semantic folders
```

### 阶段 4：正式道路段

目的：制作 500m / 1km / 多路口的可用 Town。

```text
按道路区块分 sub-level
地图命名稳定，例如 TianjinRoad01
生成 pedestrian nav
写 3-5 个基础 scenario
记录所有坐标系和导入参数
```

## 13. 验收清单

### 地图导入

```text
[ ] .fbx 和 .xodr 文件名一致
[ ] map package 名称唯一
[ ] Unreal Editor 能打开地图
[ ] 地图主体在原点附近
[ ] 路面没有明显破面、反面、悬空
```

### OpenDRIVE / 拓扑

```text
[ ] CARLA 能 load_world("TianjinRoad")
[ ] world.get_map().get_spawn_points() 数量合理
[ ] waypoint 连续
[ ] 路口 predecessor / successor 正常
[ ] 车辆不会在路口丢路
[ ] Traffic Manager 能沿路行驶
```

### 静态场景

```text
[ ] 道路、路缘、建筑、围墙、护栏 collision 正常
[ ] 红绿灯 trigger volume 覆盖正确车道
[ ] 路口交通灯已分组
[ ] 限速、停车、让行标志 trigger 合理
[ ] 建筑、围墙、杆件、植被语义分类合理
[ ] 近景资产不穿模，远景资产不过度消耗性能
```

### 行人

```text
[ ] sidewalk / crosswalk mesh 命名符合规则
[ ] 已生成 TianjinRoad.bin
[ ] .bin 放入 package Nav 目录
[ ] generate_traffic.py --walkers 可生成行人
[ ] 行人不会穿墙、穿花坛、走到不可达区域
```

### ScenarioRunner

```text
[ ] ScenarioRunner tag 为 v0.9.15
[ ] PYTHONPATH 包含 CARLA egg 和 PythonAPI/carla
[ ] 官方 FollowLeadingVehicle_1 能跑
[ ] 自定义 scenario 能加载 TianjinRoad
[ ] ego 初始位置在道路上
[ ] NPC / obstacle 坐标与地图局部坐标一致
[ ] 评价指标能正常输出
```

## 14. 常见坑

```text
1. CARLA 和 ScenarioRunner 版本不匹配。
   0.9.15 对 v0.9.15，不要直接用 master 或 0.9.16。

2. 只做了漂亮道路 mesh，没有正确 OpenDRIVE。
   视觉能看不代表车辆能导航。CARLA waypoint、Traffic Manager、ScenarioRunner 都依赖 xodr。

3. xodr/fbx 名称不一致。
   导入时必须同名。

4. 地图离原点太远。
   Unreal 精度、编辑视角、物理稳定性都会变差。

5. RoadRunner 里放太多 props。
   Unreal 导入极慢，且后期难维护。道路外环境尽量在 UE 中补。

6. 交通灯只有模型，没有 trigger volume 和 group。
   车辆可能完全不理红绿灯。

7. 没有 pedestrian nav。
   行人无法正常 spawn 和导航。

8. 没有 collision 或 collision 过重。
   轻则穿模，重则性能很差。

9. conda 污染 Python 环境。
   CARLA Python egg、ScenarioRunner requirements、系统库容易冲突。

10. 直接做完整天津道路段。
    应先做直路 demo 和单路口 demo，再扩展。
```

## 15. 推荐阅读顺序

优先读官方文档，按这个顺序：

```text
1. CARLA 0.9.15 Linux build
   https://carla.readthedocs.io/en/0.9.15/build_linux/

2. Add a new map
   https://carla.readthedocs.io/en/0.9.15/tuto_M_custom_map_overview/

3. Generating Maps in RoadRunner
   https://carla.readthedocs.io/en/0.9.15/tuto_M_generate_map/

4. Ingesting Maps in CARLA Built From Source
   https://carla.readthedocs.io/en/0.9.15/tuto_M_add_map_source/

5. Customizing Maps: Procedural Buildings
   https://carla.readthedocs.io/en/0.9.15/tuto_M_custom_buildings/

6. Customizing maps: Weather and Landscape
   https://carla.readthedocs.io/en/0.9.15/tuto_M_custom_weather_landscape/

7. Customizing maps: Traffic Lights and Signs
   https://carla.readthedocs.io/en/0.9.15/tuto_M_custom_add_tl/

8. Generate Pedestrian Navigation
   https://carla.readthedocs.io/en/0.9.15/tuto_M_generate_pedestrian_navigation/

9. ScenarioRunner Get ScenarioRunner
   https://scenario-runner.readthedocs.io/en/latest/getting_scenariorunner/

10. ScenarioRunner releases
    https://github.com/carla-simulator/scenario_runner/releases
```

非官方但有踩坑价值：

```text
Rocketloop: Importing a Custom RoadRunner Map to CARLA
https://rocketloop.de/en/blog/importing-custom-roadrunner-map-carla/
```

## 16. 建议的下一步

先不要直接做完整天津道路段。建议按下面顺序执行：

```text
1. 编译 CARLA 0.9.15 + UE 4.26，跑通 Town01 和 ScenarioRunner 官方例子。
2. RoadRunner 做一个 200m 直路，导入 CARLA，确认 make import 流程。
3. 用一个小路口验证 OpenDRIVE 拓扑、交通灯和 ScenarioRunner。
4. 再开始制作天津真实道路段。
5. 最后补静态建筑、围墙、路灯、植被和行人 nav。
```

这样风险最低，因为自定义 Town 的核心难点不是“放建筑”，而是 OpenDRIVE 拓扑、坐标系、导入链路、交通灯和 ScenarioRunner 版本/坐标对齐。
