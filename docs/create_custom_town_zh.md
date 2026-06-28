# 从零创建一个 CARLA Town

更新时间：2026-06-28 CST

本文面向当前源码编译版工作区：

```text
/mnt/carla_latest
```

可见 overlay 路径是：

```text
/media/cyun/新加卷1/disk_4090_2/carla_latest
```

命令里优先使用 `/mnt/carla_latest`，避免 UE4/CARLA 工具遇到中文路径。

## 目标

如果要自己做一个新的 Town，本质上要准备两类东西：

```text
1. 道路逻辑：OpenDRIVE .xodr
2. 可见几何：FBX mesh，通常包括道路、地面、人行道、路缘、基础设施
```

这两个文件能让 CARLA 把地图导入成一个 UE4 map。后续再在 UE4 里补材质、碰撞、语义标签、建筑、植被、灯杆、交通灯、行人导航和测试场景。

## 最小可导入文件

最小导入包只需要同名的 `.fbx` 和 `.xodr`，推荐再写一个明确的 JSON。

示例地图名：

```text
TianjinRoad
```

最小文件：

```text
TianjinRoad.fbx
TianjinRoad.xodr
TianjinRoadPackage.json
```

要求：

```text
1. FBX 和 XODR 的基础名必须一致：TianjinRoad.fbx / TianjinRoad.xodr
2. XODR 负责 waypoint、lane、junction、spawn point、Traffic Manager 路网逻辑
3. FBX 负责 UE4 里可见的道路、地面、人行道、路缘等 mesh
4. 只靠 XODR 可以做 OpenDRIVE 快速测试，但不是完整 Town
```

## 推荐工作目录

原始资料不要直接丢进 CARLA Content。先放在工作区的输入目录，确认后再导入。

```text
/mnt/carla_latest/hdmap_raw/
  原始 HD map、PCD、CAD、航拍/GIS 参考、坐标说明

/mnt/carla_latest/roadrunner/project/
  RoadRunner 工程文件

/mnt/carla_latest/roadrunner/export/
  RoadRunner 导出的 fbx/xodr/rrdata.xml

/mnt/carla_latest/custom_assets/
  自己整理的建筑、围栏、杆件、植被、纹理、材质源文件

/mnt/carla_latest/scenarios/
  OpenSCENARIO、route XML、ScenarioRunner 测试文件
```

导入 CARLA 时使用：

```text
/mnt/carla_latest/carla/carla-0.9.15/Import/
```

## 如果 Update.sh 下载 Content 失败

自建 Town 之前，CARLA 官方 Content 必须已经存在：

```text
/mnt/carla_latest/carla/carla-0.9.15/Unreal/CarlaUE4/Content/Carla
```

通常先使用 CARLA 原本方式：

```bash
cd /mnt/carla_latest/carla/carla-0.9.15
./Update.sh
```

如果官方源连接失败、速度极慢，或下载出的 `Content.tar.gz` 解压报错，不要继续用坏包。先确认版本号：

```bash
cd /mnt/carla_latest/carla/carla-0.9.15

CONTENT_ID=$(tac Util/ContentVersions.txt | egrep -m 1 . | rev | cut -d' ' -f1 | rev)
echo "$CONTENT_ID"
```

CARLA 0.9.15 正常应是：

```text
20231108_c5101a5
```

原始源码里 `Update.sh` 对新版 Content 通常使用 AWS 地址：

```text
http://carla-assets.s3.amazonaws.com/${CONTENT_ID}.tar.gz
```

如果这个源不可用，可以只把下载源改成 Backblaze：

```bash
cd /mnt/carla_latest/carla/carla-0.9.15

cp Update.sh Update.sh.bak.$(date +%Y%m%d%H%M%S)

perl -0pi -e 's#CONTENT_LINK=http://carla-assets\.s3\.amazonaws\.com/\$\{CONTENT_ID\}\.tar\.gz#CONTENT_LINK=https://carla-assets.s3.us-east-005.backblazeb2.com/${CONTENT_ID}.tar.gz#' Update.sh
perl -0pi -e 's#CONTENT_LINK=https://carla-assets\.s3\.amazonaws\.com/\$\{CONTENT_ID\}\.tar\.gz#CONTENT_LINK=https://carla-assets.s3.us-east-005.backblazeb2.com/${CONTENT_ID}.tar.gz#' Update.sh

grep -n 'CONTENT_LINK=' Update.sh
```

期望看到：

```text
CONTENT_LINK=https://carla-assets.s3.us-east-005.backblazeb2.com/${CONTENT_ID}.tar.gz
```

然后重新下载：

```bash
./Update.sh
```

也可以不改脚本，手动下载并解压：

```bash
cd /mnt/carla_latest/carla/carla-0.9.15

CONTENT_ID=$(tac Util/ContentVersions.txt | egrep -m 1 . | rev | cut -d' ' -f1 | rev)
URL="https://carla-assets.s3.us-east-005.backblazeb2.com/${CONTENT_ID}.tar.gz"

mkdir -p /tmp/carla_content_download
aria2c -x16 -s16 -k1M -c "$URL" -d /tmp/carla_content_download -o "${CONTENT_ID}.tar.gz"

tar -tzf "/tmp/carla_content_download/${CONTENT_ID}.tar.gz" >/dev/null

rm -rf Unreal/CarlaUE4/Content/Carla
mkdir -p Unreal/CarlaUE4/Content/Carla Content
tar -xzf "/tmp/carla_content_download/${CONTENT_ID}.tar.gz" -C Content
mv Content/* Unreal/CarlaUE4/Content/Carla/
rmdir Content
echo "$CONTENT_ID" > Unreal/CarlaUE4/Content/Carla/.version
```

验证：

```bash
cat Unreal/CarlaUE4/Content/Carla/.version
du -sh Unreal/CarlaUE4/Content/Carla
find Unreal/CarlaUE4/Content/Carla/Maps -maxdepth 2 -type f -name '*.umap' | head
```

注意：

```text
1. 不要把 Content tar.gz 复制进顶层 git 仓库。
2. 不要提交 Unreal/CarlaUE4/Content/Carla 里的 .uasset/.umap 大资源。
3. 只改下载 URL，不要随便改 ContentVersions.txt 里的版本号。
4. 如果 tar 解压出现 "Skipping to next header" 或 "failure status"，通常是包没下完整，应该删除后重新下载。
```

## 从 RoadRunner 导出

推荐用 RoadRunner 做道路拓扑和基础路面，因为它能同时导出 XODR 和 FBX。

导出前检查：

```text
1. 地图尽量以合理原点居中，避免坐标过大导致 UE4 精度问题
2. OpenDRIVE Preview 里检查 lane、junction、turn、stop line、signal
3. 道路、人行道、路缘、斑马线等 mesh 和 XODR 坐标一致
4. 导出的 .fbx 和 .xodr 名字一致
```

RoadRunner 导出选项通常选择：

```text
File -> Export -> CARLA (.fbx, .xodr, .rrdata.xml)
```

建议：

```text
Split by Segmentation: 开启，方便 CARLA/UE4 按语义拆 mesh
Power of Two Texture Dimensions: 开启
Embed Textures: 可开启
Export Individual Tiles: 小地图先关闭，大地图再考虑分块
```

## 准备 Import 包

在 CARLA 源码根目录下建立导入包：

```bash
cd /mnt/carla_latest/carla/carla-0.9.15

mkdir -p Import/TianjinRoadPackage/TianjinRoad
```

把导出的文件放进去：

```text
/mnt/carla_latest/carla/carla-0.9.15/Import/TianjinRoadPackage/
├── TianjinRoadPackage.json
└── TianjinRoad/
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

字段含义：

```text
name:
  地图名。建议和 fbx/xodr 基础名一致。

source:
  FBX 相对 JSON 的路径。

xodr:
  OpenDRIVE 相对 JSON 的路径。

use_carla_materials:
  true 表示优先使用 CARLA 默认道路材质；false 表示更多使用导入材质。
```

## 导入地图

先确认环境变量：

```bash
export UE4_ROOT=/mnt/carla_latest/ue/UnrealEngine_4.26
export CARLA_ROOT=/mnt/carla_latest/carla/carla-0.9.15
```

执行导入：

```bash
cd "$CARLA_ROOT"
make import ARGS="--package=TianjinRoadPackage"
```

导入后会生成类似目录：

```text
/mnt/carla_latest/carla/carla-0.9.15/Unreal/CarlaUE4/Content/TianjinRoadPackage/
├── Config/
├── Maps/
│   ├── TianjinRoad.umap
│   ├── OpenDrive/TianjinRoad.xodr
│   ├── Nav/
│   └── TM/
├── Static/
├── Materials/
└── Textures/
```

实际目录会随导入内容变化。不要手动把大 FBX、纹理、生成的 `.uasset` 提交到远程源码仓库。

## 打开自定义 Town

启动编辑器并打开新地图：

```bash
VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json \
/mnt/carla_latest/ue/UnrealEngine_4.26/Engine/Binaries/Linux/UE4Editor \
  /mnt/carla_latest/carla/carla-0.9.15/Unreal/CarlaUE4/CarlaUE4.uproject \
  /Game/TianjinRoadPackage/Maps/TianjinRoad \
  -vulkan -nosound -nop4 -preferNvidia
```

如果只是打开项目，不直接加载地图：

```bash
VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json \
/mnt/carla_latest/ue/UnrealEngine_4.26/Engine/Binaries/Linux/UE4Editor \
  /mnt/carla_latest/carla/carla-0.9.15/Unreal/CarlaUE4/CarlaUE4.uproject \
  -vulkan -nosound -nop4 -preferNvidia
```

## UE4 里必须检查的内容

导入后不是结束。一个可用 Town 至少要检查：

```text
1. 地图 mesh 是否和 XODR 路网对齐
2. 道路、人行道、路缘、地面是否有正确材质
3. 道路、建筑、护栏、墙体、杆件是否有碰撞
4. PlayerStart 和车辆 spawn point 是否合理
5. XODR 里的 lane、junction、traffic sign、traffic light 逻辑是否正确
6. UE4 里的 traffic light actor、trigger volume、stop line 是否对齐
7. 语义标签是否正确，尤其是 road、sidewalk、building、vegetation、pole、traffic sign
8. 夜间/雨天/低画质下材质和灯光是否正常
```

官方 Town 通常会拆 sublevel，例如：

```text
Ground
Buildings
Props
Foliage
Streetlights
Decals
Walls
Parked_Vehicles
Rendering_and_Lightning_components
```

自建地图一开始可以不拆，但地图变大后建议拆 sublevel，方便编辑和加载。

## 行人导航 Nav 文件

如果需要 pedestrians/walkers，必须生成行人导航 `.bin`。

UE4 中先完成地图定制，再生成 Nav，避免后续建筑或障碍物挡住行人路径。

关键命名规则：

```text
Road_Sidewalk 或 Roads_Sidewalk:
  行人可自由行走的人行道

Road_Crosswalk 或 Roads_Crosswalk:
  斑马线/横穿道路区域

Road_Grass 或 Roads_Grass:
  草地，可按需要允许部分行人进入

Road_Road / Roads_Road:
  车辆道路，行人通常只在 crosswalk 处穿越
```

生成流程：

```text
1. 在 UE4 中把不参与导航的大对象加 NoExport tag，例如天空盒
2. 检查 sidewalk/crosswalk/grass/road mesh 名称
3. 在 UE4 菜单使用 File -> Carla Exporter，导出 <MapName>.obj 到 Saved
4. 把 <MapName>.obj 和 <MapName>.xodr 放到 Util/DockerUtils/dist
5. 执行 build.sh 生成 <MapName>.bin
6. 把 .bin 放回地图包的 Maps/Nav 目录
```

命令形态：

```bash
cd /mnt/carla_latest/carla/carla-0.9.15

cp Unreal/CarlaUE4/Saved/TianjinRoad.obj Util/DockerUtils/dist/
cp Unreal/CarlaUE4/Content/TianjinRoadPackage/Maps/OpenDrive/TianjinRoad.xodr Util/DockerUtils/dist/

cd Util/DockerUtils/dist
./build.sh TianjinRoad

mkdir -p /mnt/carla_latest/carla/carla-0.9.15/Unreal/CarlaUE4/Content/TianjinRoadPackage/Maps/Nav
cp TianjinRoad.bin /mnt/carla_latest/carla/carla-0.9.15/Unreal/CarlaUE4/Content/TianjinRoadPackage/Maps/Nav/
```

如果 `make import` 已经自动生成了可用 Nav，可以先测试；如果 pedestrians 行为不对，再按上面的方式重新生成。

## Traffic Manager 缓存

CARLA 0.9.15 的 Traffic Manager 会基于 OpenDRIVE 构建内部路网缓存。导入流程里也可能生成 `Maps/TM/<MapName>.bin`。

如果没有 TM 缓存，运行时可能出现类似：

```text
No InMemoryMap cache found. Setting up local map. This may take a while...
```

这通常不是致命错误，只是第一次构建会慢。地图道路逻辑变化后，需要重新导入或重新生成相关缓存。

## 测试命令

启动 CARLA Editor 后，可以用 PythonAPI 做基础检查。

激活环境：

```bash
source /mnt/carla_latest/venvs/carla0915-py38/bin/activate

export PYTHONPATH=/mnt/carla_latest/scenario_runner/scenario_runner-v0.9.15:$PYTHONPATH
export PYTHONPATH=/mnt/carla_latest/carla/carla-0.9.15/PythonAPI/carla:$PYTHONPATH
export PYTHONPATH="$(find /mnt/carla_latest/carla/carla-0.9.15/PythonAPI/carla/dist -name 'carla-0.9.15-py3.*-linux-x86_64.egg' | sort | head -n 1):$PYTHONPATH"
```

检查地图是否能加载、是否有 spawn points：

```bash
python - <<'PY'
import carla

client = carla.Client("127.0.0.1", 2000)
client.set_timeout(20.0)
world = client.get_world()
mp = world.get_map()
print("map:", mp.name)
print("spawn_points:", len(mp.get_spawn_points()))
print("topology_edges:", len(mp.get_topology()))
PY
```

测试自动交通：

```bash
cd /mnt/carla_latest/carla/carla-0.9.15/PythonAPI/examples
python generate_traffic.py --number-of-vehicles 20 --number-of-walkers 20
```

如果 vehicles 不能正常走，优先检查 XODR lane/junction/spawn point。
如果 walkers 不正常，优先检查 Nav `.bin` 和 sidewalk/crosswalk mesh 命名。

## 场景文件

自建 Town 稳定后，再补 ScenarioRunner 数据：

```text
/mnt/carla_latest/scenarios/routes/
  路线 XML

/mnt/carla_latest/scenarios/openscenario/
  OpenSCENARIO .xosc / .osc

/mnt/carla_latest/scenarios/xml/
  ScenarioRunner 传统 XML 场景
```

路线文件里的地图名要和 CARLA 里加载到的 map 名匹配，例如：

```text
TianjinRoad
```

## 文件是否需要提交远程

这个仓库远程只适合放源码、脚本和文档，不适合放大资源。

不要提交：

```text
Unreal/CarlaUE4/Content/**/*.uasset
Unreal/CarlaUE4/Content/**/*.umap
*.fbx
*.obj
*.bin
*.tar.gz
venvs/
ue/
carla/
DerivedDataCache/
Saved/
Intermediate/
Binaries/
```

可以提交：

```text
docs/*.md
README.md
小型配置说明
自定义脚本源码
小型 JSON 模板
```

如果后续确实要版本化地图源数据，建议单独建资源仓库或使用 Git LFS，并明确区分：

```text
源码/文档仓库：小文件，可直接 git push
资产仓库：FBX、贴图、uasset、umap、Nav/TM bin、发布包
```

## 常见问题

### 只有 XODR 能不能成为 Town？

不能成为完整 Town。XODR 可以让 CARLA 创建道路逻辑，也能做 OpenDRIVE 测试，但没有 UE4 可见城市几何。完整 Town 需要 FBX/UE4 map/材质/碰撞等内容。

### PCD 能不能直接变成 Town？

PCD 只是点云参考。它能帮助对齐道路、建筑和地形，但还需要从 PCD/CAD/HD map 重建 XODR 和 FBX。

### 导入后为什么第一次很慢？

UE4 会生成 shader、DerivedDataCache、材质和 mesh 派生数据。第一次慢是正常的；缓存保存成功后后续会快很多。

### 可以直接复制官方 Town 再改吗？

可以作为学习方式，但正式自建地图建议独立 package，例如 `TianjinRoadPackage`，避免污染官方 `Content/Carla/Maps`。

### 新机器上怎么打开？

先挂载 overlay：

```bash
/media/cyun/新加卷1/disk_4090_2/mount_carla.sh
```

再用 `/mnt/carla_latest` 路径启动。新机器仍然需要系统依赖、NVIDIA 驱动/Vulkan、UE4/CARLA 编译产物和 Content 资源都存在。
