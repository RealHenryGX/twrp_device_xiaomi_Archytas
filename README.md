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

The Archytas Wi-Fi recovery uses the prebuilt 64-bit agui kernel. The working
USB setup uses ConfigFS with `mtp.gs0` and `ffs.adb`; the TWRP ramdisk enables
data-media before processing `/data` (`RECOVERY_SDCARD_ON_DATA := true`). TWRP
creates `/data/media`, exposes it through `/sdcard`, and registers that directory
as the MTP Internal Storage object. Do not add a second userdata mount at
`/sdcard` in `recovery.fstab`.

Verified on device with recovery build 43347476866: `adb` enumerates,
`sys.usb.state=mtp,adb`, `/sdcard` reports the userdata capacity, and the
recovery log registers Internal Storage without the earlier `/data/media`
open error. Windows Explorer visibility still requires a host-side check.

On this bootloader, `fastboot reboot recovery` can report OKAY without entering
Recovery. After flashing, enter Recovery manually with the hardware key
combination and verify `ro.boot.mode=recovery` before evaluating the image.
