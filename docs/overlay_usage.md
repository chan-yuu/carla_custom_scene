# CARLA Latest Overlay Usage

Updated: 2026-06-28 CST

This is the active workspace for the new CARLA 0.9.15 source-build setup:

```text
/media/cyun/新加卷1/disk_4090_2/carla_latest
```

Mount it with the workspace mount script:

```bash
/media/cyun/新加卷1/disk_4090_2/mount_carla.sh
```

That script is the correct entrypoint for this workspace. It mounts one root
overlay workspace and also creates an ASCII bind-mount entrypoint:

```text
visible workspace:
/media/cyun/新加卷1/disk_4090_2/carla_latest

ASCII command path:
/mnt/carla_latest
```

Use `/mnt/carla_latest` for CARLA, Unreal Engine, ScenarioRunner, Python venv,
build, import, and editor commands. The visible `/media/.../carla_latest` path
is still the same workspace, but UE4/CARLA build tools are safer when launched
from an ASCII-only path.

There should not be a second mount under
`/mnt/carla_latest/carla/carla-0.9.15/Unreal/CarlaUE4/Content/Carla`. CARLA
assets are normal files inside the root overlay.

Check the active root overlay:

```bash
findmnt -R /mnt/carla_latest
```

The expected result is only one `overlay` line for `/mnt/carla_latest`.

## Overlay Internals

The overlay internals are:

```text
ext4 store image:
/media/cyun/新加卷1/disk_4090_2/.carla_latest_overlay_store.ext4

ext4 store mount:
/mnt/carla_latest_overlay_store

lower skeleton:
/mnt/carla_latest_overlay_store/carla_latest_overlay/lower

writable overlay layer:
/mnt/carla_latest_overlay_store/carla_latest_overlay/upper

overlay work directory:
/mnt/carla_latest_overlay_store/carla_latest_overlay/work
```

The visible disk is NTFS/fuseblk, and Linux overlay upper/work cannot live
directly on that filesystem. The mount script therefore creates and mounts an
ext4 loop image stored under `disk_4090_2`, then uses that ext4 filesystem for
overlay lower/upper/work. This keeps the new workspace on the new disk while
satisfying overlayfs requirements.

Meaning:

```text
lower:
  Read-only base layer. The script expects the workspace skeleton here.

upper:
  Writable layer. New files, modified files, downloaded source trees, UE4 build
  output, CARLA assets, venvs, custom maps, and logs are stored here.

work:
  Required internal scratch directory used by Linux overlayfs. Do not put user
  files here.

/mnt/carla_latest:
  The merged view. Use this path for all normal work.
```

From the user/workflow perspective, all new source trees, downloaded
dependencies, CARLA assets, build products, and custom maps belong under:

```text
/mnt/carla_latest
```

or equivalently under:

```text
/media/cyun/新加卷1/disk_4090_2/carla_latest
```

Check the active mounts:

```bash
findmnt -T /mnt/carla_latest_overlay_store
findmnt -T /media/cyun/新加卷1/disk_4090_2/carla_latest
findmnt -T /mnt/carla_latest
```

Unmount manually when needed:

```bash
sudo umount /mnt/carla_latest
sudo umount /media/cyun/新加卷1/disk_4090_2/carla_latest
sudo umount /mnt/carla_latest_overlay_store
```

Historical note: previous CARLA workspaces such as
`/media/cyun/新加卷1/disk_4090/carla_compiled` and related overlay/bind mounts
are old references only. They are not the target for the new clean setup.

## Moving To Another Machine

Yes, the mount can be recreated on another machine with one shell script, as
long as the required files are present and the machine supports Linux
overlayfs/loop mounts.

Copy these together:

```text
/media/cyun/新加卷1/disk_4090_2/mount_carla.sh
/media/cyun/新加卷1/disk_4090_2/.carla_latest_overlay_store.ext4
```

On the new machine, `CARLA_BASE` means the directory where the plugged-in disk
contains these two files:

```text
mount_carla.sh
.carla_latest_overlay_store.ext4
```

It is not `/mnt/carla_latest`. `/mnt/carla_latest` is created by the mount
script after the overlay is mounted.

Example: after plugging the disk into another computer, first find the script:

```bash
find /media "$HOME" -name mount_carla.sh 2>/dev/null
```

If it prints:

```text
/media/alice/NewVolume/disk_4090_2/mount_carla.sh
```

then the new disk root is:

```text
/media/alice/NewVolume/disk_4090_2
```

Mount with:

```bash
export CARLA_BASE=/media/alice/NewVolume/disk_4090_2
"$CARLA_BASE/mount_carla.sh"
cd /mnt/carla_latest
```

If the disk happens to mount at the same path as this machine, just run:

```bash
/media/cyun/新加卷1/disk_4090_2/mount_carla.sh
cd /mnt/carla_latest
```

Useful overrides:

```text
CARLA_BASE               disk root containing the store image and mount script
CARLA_PROJECT            default: carla_latest
CARLA_VISIBLE_MOUNTPOINT default: $CARLA_BASE/carla_latest
CARLA_ASCII_MOUNTPOINT   default: /mnt/carla_latest
CARLA_STORE_IMAGE        default: $CARLA_BASE/.carla_latest_overlay_store.ext4
CARLA_STORE_MOUNT        default: /mnt/carla_latest_overlay_store
CARLA_OVERLAY_STORE_SIZE default: 350G, only used when creating a new image
```

If `.carla_latest_overlay_store.ext4` is not copied, the script will create a
new empty backing image instead of showing the existing CARLA workspace.
