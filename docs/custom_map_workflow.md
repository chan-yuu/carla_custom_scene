# CARLA 自定义地图工作流说明

Updated: 2026-06-26 21:25 CST

这份文档回答当前几个和自定义地图直接相关的问题：

```text
1. 哪些目录可以删，哪些不要动
2. RoadRunner 是什么作用
3. 只有 PCD 点云和 XODR 高精地图时，怎么做成 CARLA 场景地图
4. UE4Editor 启动的是哪个项目
5. 一个完整 CARLA 地图包通常包含哪些东西
```

## 1. 目录清理判断

当前大目录大小大致如下：

```text
98G   /mnt/carla_compiled/ue
32G   /mnt/carla_compiled/carla
21G   /mnt/carla_assets_stage/carla_assets_0915
2.8G  /mnt/carla_assets_stage/carla_ue_ddc
292M  /mnt/carla_compiled/venvs
53M   /mnt/carla_compiled/scenario_runner
15M   /mnt/carla_compiled/test_logs
8.9M  /mnt/carla_compiled/build_logs
0     /mnt/carla_compiled/hdmap_raw
0     /mnt/carla_compiled/roadrunner
0     /mnt/carla_compiled/scenarios
4K    /mnt/carla_compiled/custom_assets
```

不要删除：

```text
/mnt/carla_compiled/ue
/mnt/carla_compiled/carla
/mnt/carla_compiled/venvs
/mnt/carla_compiled/scenario_runner
/mnt/carla_compiled/scripts
/mnt/carla_compiled/docs
/mnt/carla_assets_stage/carla_assets_0915
/mnt/carla_assets_stage/carla_ue_ddc
```

原因：

```text
ue:                 UE4Editor 和 UE4 编译产物
carla:              CARLA 源码、Unreal 项目、PythonAPI、插件
venvs:              Python 3.8 环境
scenario_runner:    ScenarioRunner v0.9.15
scripts/docs:        本地启动、检查、文档
carla_assets_0915:  官方 CARLA Content/Carla 资产，当前是 bind mount 来源
carla_ue_ddc:       UE shader/mesh 缓存，删了会导致下次重新长时间编译
```

可以删但不建议现在删：

```text
/mnt/carla_compiled/hdmap_raw
/mnt/carla_compiled/roadrunner
/mnt/carla_compiled/custom_assets
/mnt/carla_compiled/scenarios
```

这些目录现在几乎是空的，占不了空间，但它们正好是后续做自定义地图需要的工作区：

```text
hdmap_raw:      放 PCD、原始高精地图、坐标系说明
roadrunner:     放 RoadRunner 工程和导出的 FBX/XODR
custom_assets:  放建筑、围墙、杆件、植被、贴图等自定义静态资产
scenarios:      放 ScenarioRunner 的 xosc/xml/routes
```

可以按需清理：

```text
/mnt/carla_compiled/build_logs
/mnt/carla_compiled/test_logs
```

它们只是日志和截图，删了不会影响运行。但这些日志能证明编译和 GUI 验证过程，建议至少保留最近一次成功日志。

不要继续碰这个坏目录：

```text
/mnt/carla_compiled/carla/carla-0.9.15/Content.broken_20260626_1826
```

它不是权限问题，`sudo rm -rf` 也删不掉，是外置 NTFS 盘目录项 I/O 错误。等文件系统离线修复后再删。

## 2. RoadRunner 的作用

RoadRunner 是 MathWorks 的道路场景编辑器。对 CARLA 自定义地图来说，它的核心作用是把“道路逻辑”和“可视化几何”一起整理出来。

它通常负责：

```text
1. 设计或修正道路平面线形、车道、路口、人行道、停车区。
2. 导入或对照点云、航拍图、GIS/HD map 资料来重建道路。
3. 检查 OpenDRIVE 网络是否连通，车道方向、junction、lane marking 是否合理。
4. 导出 CARLA 可用的:
   - <MapName>.xodr
   - <MapName>.fbx
   - <MapName>.rrdata.xml
```

各文件角色：

```text
XODR:
  OpenDRIVE 道路逻辑。CARLA 用它生成 waypoint、lane、junction、
  路由、Traffic Manager、lane invasion、landmark 等逻辑信息。

FBX:
  UE4 可见的 3D 几何。道路、人行道、地面、路肩、部分基础设施等
  需要以 mesh 形式进入 Unreal Editor。

RRDATA:
  RoadRunner 到 CARLA import 的辅助数据，保留材质、语义、信号等额外信息。

PCD:
  点云。它通常是重建道路和静态环境的参考数据，不是 CARLA 直接可跑的地图。
```

如果你已经有 `.xodr`，RoadRunner 仍然有价值：可以导入/对照它，修路口、车道、停止线、信号和 lane marking，然后导出和 XODR 对齐的 FBX。

## 3. 从 PCD/XODR 构建 CARLA 场景地图

你现在知道有：

```text
*.pcd   # 点云
*.xodr  # OpenDRIVE 高精地图
```

这还不够做完整 CARLA Town。最小还需要：

```text
*.fbx   # 可视化/碰撞 mesh，至少要有道路和地面
```

推荐流程：

```text
PCD / HD map / CAD / 航拍
        ↓
坐标系整理，选择地图原点，统一 ENU/UE 坐标
        ↓
检查或修正 XODR
        ↓
生成和 XODR 对齐的道路/地面 FBX
        ↓
放入 CARLA Import 目录
        ↓
make import
        ↓
UE4Editor 中补静态环境、材质、碰撞、语义标签、交通灯
        ↓
生成 pedestrian nav .bin，必要时生成 TM 数据
        ↓
运行 CARLA/ScenarioRunner 验证
        ↓
make package，可选
```

最小导入结构：

```text
/mnt/carla_compiled/carla/carla-0.9.15/Import
└── TianjinRoadPackage
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

导入命令：

```bash
cd /mnt/carla_compiled/carla/carla-0.9.15
make import ARGS="--package=TianjinRoadPackage"
```

导入后通常会生成：

```text
/mnt/carla_compiled/carla/carla-0.9.15/Unreal/CarlaUE4/Content/TianjinRoadPackage
```

然后用 UE4Editor 打开：

```bash
/mnt/carla_compiled/scripts/launch_carla_editor.sh \
  --detach \
  --map /Game/TianjinRoadPackage/Maps/TianjinRoad \
  -nosound -nop4
```

在 UE4 里要做的事：

```text
1. 检查地图是否和 XODR 对齐。
2. 补道路材质、路面 decal、车道线显示。
3. 给道路、建筑、护栏等加 collision。
4. 设置 semantic tag，否则传感器语义分割不准。
5. 放建筑、围墙、路灯、树、交通灯杆、标志牌。
6. 检查 PlayerStart/spawn points。
7. 检查 traffic light trigger volume 和 stop line 关系。
8. 保存所有 sublevels。
```

只有 XODR 也可以临时跑逻辑测试：CARLA Python API 有 OpenDRIVE standalone mode，可以从 XODR 生成基础道路世界。但这种模式没有完整城市场景资产，不适合你要的 UE4 自定义 Town。

## 4. UE4Editor 启动的是哪个项目

当前脚本启动的不是 UE 引擎目录本身，而是 CARLA 的 UE4 项目：

```text
项目文件:
/mnt/carla_compiled/carla/carla-0.9.15/Unreal/CarlaUE4/CarlaUE4.uproject

项目根目录:
/mnt/carla_compiled/carla/carla-0.9.15/Unreal/CarlaUE4

UE4Editor 二进制:
/mnt/carla_compiled/ue/UnrealEngine_4.26/Engine/Binaries/Linux/UE4Editor
```

当前实际启动命令形式：

```bash
/mnt/carla_compiled/ue/UnrealEngine_4.26/Engine/Binaries/Linux/UE4Editor \
  /mnt/carla_compiled/carla/carla-0.9.15/Unreal/CarlaUE4/CarlaUE4.uproject \
  /Game/Carla/Maps/Town01_Opt \
  -vulkan -nosound -nop4
```

当前官方资产路径：

```text
/mnt/carla_compiled/carla/carla-0.9.15/Unreal/CarlaUE4/Content/Carla
```

但它实际是 bind mount 到：

```text
/mnt/carla_assets_stage/carla_assets_0915/Carla
```

所以在 UE4 Content Browser 里看到的 `/Game/Carla/...`，对应磁盘上的 `Unreal/CarlaUE4/Content/Carla/...`。

## 5. 一个完整地图包含什么

以官方 `Town01_Opt` 为例，它不是一个单独文件，而是一组 UE 资产、OpenDRIVE、导航文件和辅助数据。

核心文件：

```text
Content/Carla/Maps/Town01_Opt.umap
Content/Carla/Maps/OpenDrive/Town01_Opt.xodr
Content/Carla/Maps/Nav/Town01_Opt.bin
Content/Carla/Maps/TM/Town01_Opt.bin
Content/Carla/Maps/Town01_BuiltData.uasset
```

`Town01_Opt.umap` 是主地图 level。`Town01_Opt.xodr` 是道路逻辑。`Nav/Town01_Opt.bin` 是行人导航。`TM/Town01_Opt.bin` 是 Traffic Manager 相关数据。`BuiltData.uasset` 保存构建后的光照等 UE 数据。

官方 `Town01_Opt` 还有一组 sublevels：

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

这些 sublevels 把地图拆成不同层，方便编辑和流式加载：

```text
Ground:       地面、道路、基础地形
Buildings:    建筑
Props:        道具
Foliage:      植被
Walls:        墙、围栏
Streetlights: 路灯
Decals:       路面贴花、污渍、标线等
Parked cars:  停放车辆
Rendering:    天空、光照、天气、后处理
Layout:       布局和组织性 actor
```

地图还依赖大量共享资产：

```text
Content/Carla/Static/...       # 道路、建筑、护栏、道具等 static mesh
Content/Carla/Blueprints/...   # 交通灯、建筑生成、天气、车辆/传感器等蓝图
Content/Carla/Materials/...    # 材质
Content/Carla/Textures/...     # 贴图
```

对你自己的地图，建议目标结构类似：

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

最小可运行地图可以先只有：

```text
TianjinRoad.umap
OpenDrive/TianjinRoad.xodr
道路/地面 mesh
基础材质
collision
```

如果要支持行人、交通流、传感器语义、复杂场景评测，再逐步补：

```text
Nav .bin
TM .bin
traffic lights / signs
semantic tags
sublevels
props / buildings / vegetation
ScenarioRunner routes and scenarios
```
