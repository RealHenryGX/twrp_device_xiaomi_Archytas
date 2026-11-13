# Android device tree for Xiaomi Archytas (Archytas)

```
#
# Copyright (C) 2023 The Android Open Source Project
# Copyright (C) 2023 SebaUbuntu's TWRP device tree generator
#
# SPDX-License-Identifier: Apache-2.0
#
```

## Recovery storage and USB

The Archytas Wi-Fi recovery uses the prebuilt 64-bit agui kernel. The proposed
USB setup uses ConfigFS with `ffs.mtp` and `ffs.adb`; the TWRP ramdisk enables
data-media before processing `/data` (`RECOVERY_SDCARD_ON_DATA := true`). TWRP
creates `/data/media`, exposes it through `/sdcard`, and registers that directory
as the MTP Internal Storage object. Do not add a second userdata mount at
`/sdcard` in `recovery.fstab`.

Verified on device with recovery build 43347476866: `adb` enumerates,
`sys.usb.state=mtp,adb`, `/sdcard` reports the userdata capacity, and the
recovery log registers Internal Storage without the earlier `/data/media`
open error. That build still bound the host MTP interface to `mtp.gs0`, while
TWRP's MTP server used `/dev/usb-ffs/mtp`. The device tree now binds `ffs.mtp`
after its endpoints become ready; host visibility needs verification after a
new build and flash.

On this bootloader, `fastboot reboot recovery` can report OKAY without entering
Recovery. After flashing, enter Recovery manually with the hardware key
combination and verify `ro.boot.mode=recovery` before evaluating the image.

## Historical change audit

These labels describe runtime evidence, not whether a commit builds. Keep the
history intact; avoid cherry-picking a superseded USB rule into a new tree.

| Commit | Status | Maintainer note |
| --- | --- | --- |
| `126678d`, `b40097f` | Superseded / ineffective | Early MT6761 ADB changes and a comment-only legacy-USB change. Current device reports `ro.hardware=mt8766`. |
| `a655295` | Partially valid | Removing the `mt_usb` fstab entry fixed the `Unknown File System` error; its MT6761 USB properties were not the active runtime path. |
| `a71eeac` | Invalid for TWRP MTP | Bound the host to `mtp.gs0` while TWRP served `/dev/usb-ffs/mtp`. This enumerated an interface without exposing TWRP's internal-storage list. |
| `5cf4add` | ADB valid, MTP incomplete | Restored ADB and USB enumeration, but retained the `mtp.gs0` mismatch. |
| `f81330e` | Incorrect rationale | `/sdcard` build variables alone did not create internal storage. |
| `f74fcd6` | Verified | Early data-media initialization created `/data/media` and made `/sdcard` show userdata capacity. |
| `7fc563f` | Verified | Removed five absent Wi-Fi partition entries from the running fstab. |
| `6fbd587` | Awaiting host validation | Replaces `mtp.gs0` with `ffs.mtp`; check Windows Explorer and ADB together after flashing. |

The pre-existing `auto /devices/platform/externdevice*` fstab entry appears as
`/auto0` with 0 MB and storage ID 65537 when no external device is attached.
Internal Storage is a separate 11 GB entry with storage ID 65538. Evaluate
external-media support before changing the wildcard entry.
