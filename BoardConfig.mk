#
# Copyright (C) 2023 The Android Open Source Project
# Copyright (C) 2023 SebaUbuntu's TWRP device tree generator
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/xiaomi/Archytas

# For building with minimal manifest
ALLOW_MISSING_DEPENDENCIES := true

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := generic

TARGET_USES_64_BIT_BINDER := true

# APEX
OVERRIDE_TARGET_FLATTEN_APEX := true

# Bootloader
TARGET_BOOTLOADER_BOARD_NAME := Archytas
TARGET_NO_BOOTLOADER := true

# Display
TARGET_SCREEN_DENSITY := 240

# Kernel
BOARD_BOOTIMG_HEADER_VERSION := 1
BOARD_KERNEL_BASE := 0x40078000
BOARD_KERNEL_CMDLINE := bootopt=64S3,32S1,64S1 buildvariant=userdebug
BOARD_KERNEL_PAGESIZE := 2048
BOARD_RAMDISK_OFFSET := 0x11a88000
BOARD_KERNEL_TAGS_OFFSET := 0x07808000
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOTIMG_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS += --ramdisk_offset $(BOARD_RAMDISK_OFFSET)
BOARD_MKBOOTIMG_ARGS += --tags_offset $(BOARD_KERNEL_TAGS_OFFSET)
BOARD_KERNEL_IMAGE_NAME := Image.gz-dtb
BOARD_KERNEL_SEPARATED_DTBO := false
TARGET_KERNEL_CONFIG := Archytas_defconfig
TARGET_KERNEL_SOURCE := kernel/xiaomi/Archytas

# Kernel - prebuilt
TARGET_FORCE_PREBUILT_KERNEL := true
ifeq ($(TARGET_FORCE_PREBUILT_KERNEL),true)
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/kernel

endif

# Partitions
BOARD_BUILD_SYSTEM_ROOT_IMAGE := true
BOARD_FLASH_BLOCK_SIZE := 131072 # (BOARD_KERNEL_PAGESIZE * 64)
BOARD_BOOTIMAGE_PARTITION_SIZE := 33554432
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 33554432
BOARD_HAS_LARGE_FILESYSTEM := true
BOARD_SYSTEMIMAGE_PARTITION_TYPE := ext4
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
TARGET_COPY_OUT_VENDOR := vendor

# Platform
TARGET_BOARD_PLATFORM := mt6761

# Recovery
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true

# Security patch level
VENDOR_SECURITY_PATCH := 2021-08-01

# Verified Boot
# BOARD_AVB_ENABLE := true
# BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3
# BOARD_AVB_RECOVERY_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
# BOARD_AVB_RECOVERY_ALGORITHM := SHA256_RSA4096
# BOARD_AVB_RECOVERY_ROLLBACK_INDEX := 1
# BOARD_AVB_RECOVERY_ROLLBACK_INDEX_LOCATION := 1

# Hack: prevent anti rollback
PLATFORM_SECURITY_PATCH := 2099-12-31
VENDOR_SECURITY_PATCH := 2099-12-31
PLATFORM_VERSION := 16.1.0

# TWRP Configuration
TW_THEME := portrait_hdpi
TW_EXTRA_LANGUAGES := true
TW_SCREEN_BLANK_ON_BOOT := true
TW_INPUT_BLACKLIST := "hbtp_vm"
TW_USE_TOOLBOX := true
# recovery 环境无 health HAL 服务,TWRP 3.7.x 默认走 HIDL GetBatteryInfo 取不到电量;
# 改为直读 /sys/class/power_supply/battery/capacity(实机节点完好)
TW_USE_LEGACY_BATTERY_SERVICES := true
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab

# SHRP Configuration
################### ############################################
# MANDATORY FLAGS # These flags HAVE TO be set/changed by you! #
################### ############################################

# Device codename
# Default (if not set): N/A
SHRP_DEVICE_CODE := Archytas

# Path of your SHRP device tree
# Replace <device-brand> with the device brand name
# (SHRP_DEVICE_CODE will expand to the above variable so check if that is correct)
SHRP_PATH := device/xiaomi/$(SHRP_DEVICE_CODE)

# Maintainer name
# Default (if not set): N/A
SHRP_MAINTAINER := what_the_bruhhhh

# Recovery Type (for "About" section only)
# Default (if not set): N/A
SHRP_REC_TYPE := SAR

# Device Type (for "About" section only)
# Default (if not set): N/A
SHRP_DEVICE_TYPE := A_Only

# Your device's recovery path, dont use blindly
# Default (if not set): N/A
SHRP_REC := /dev/block/platform/bootdevice/by-name/recovery

################### ################################################################################
# IMPORTANT FLAGS # These are usually good to check - at least if the defaults are what you expect #
################### ################################################################################

# Emergency DownLoad mode (0 = no EDL mode, 1 = EDL mode available)
# Default (if not set): 0
SHRP_EDL_MODE := 0

# Internal storage path
# Default (if not set): /sdcard
SHRP_INTERNAL := /sdcard

# External SDcard path
# Default (if not set): /
SHRP_EXTERNAL := /external_sd

# USB OTG path
# Default (if not set): /
SHRP_OTG := /usb_otg

# Flashlight: (0 = disable, 1 = enable)
# Default (if not set): 0
SHRP_FLASH := 0


# 纯 64 位用户态(无 2ND_ARCH)
TARGET_SUPPORTS_64_BIT_APPS := true
