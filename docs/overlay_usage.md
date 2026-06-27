# CARLA Latest Overlay Usage

Updated: 2026-06-27 CST

This workspace uses one overlay mount only. The visible project directory is:

```text
/media/cyun/新加卷1/disk_4090_2/carla_latest
```

Mount it with:

```bash
/media/cyun/新加卷1/disk_4090_2/mount_carla.sh
```

The mount layout is:

```text
visible workspace:
/media/cyun/新加卷1/disk_4090_2/carla_latest

base skeleton and docs:
/media/cyun/新加卷1/disk_4090_2/carla_latest_lower

writable overlay layer:
/mnt/carla_assets_stage/carla_latest_overlay/upper

overlay work directory:
/mnt/carla_assets_stage/carla_latest_overlay/work
```

Use `carla_latest` for normal work. Do not put source trees, downloaded
dependencies, build products, or CARLA assets into the base skeleton directory.

Check the active mount:

```bash
findmnt -T /media/cyun/新加卷1/disk_4090_2/carla_latest
```

Unmount manually when needed:

```bash
sudo umount /media/cyun/新加卷1/disk_4090_2/carla_latest
```

The only external script that belongs to this workspace is:

```text
/media/cyun/新加卷1/disk_4090_2/mount_carla.sh
```
