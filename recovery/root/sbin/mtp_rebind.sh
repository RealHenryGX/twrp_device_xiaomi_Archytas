#!/sbin/sh
# mtp_rebind.sh — rebind configfs gadget after TWRP MTP daemon becomes active.
#
# Root cause (verified on-device 2026-10-31, dmesg + TWRP 3.7.1 source):
#   TWPartitionManager::Enable_MTP() does:
#       1. property_set("sys.usb.config", "none");
#       2. write legacy android0 idVendor/idProduct (fails: configfs kernel has no android0);
#       3. property_set("sys.usb.config", "mtp,adb");   <-- init immediately rebinds configfs
#       4. fork() twrpMtp -> MtpServer, which FIRST usleep(800000) then opens
#          /dev/usb-ffs/mtp/ep0 and performs FUNCTIONFS_BIND.
#   So the configfs bind at step 3 runs while ffs.mtp has no daemon yet ->
#   ffs_func_bind() returns -EBADFD (-77) -> "failed to start g1" -> USB dead ->
#   sys.usb.ffs.ready never set -> adbd open/retry loop, TWRP Stop/Start MTP cycle.
#
# Fix: wait until BOTH functionfs daemons are active (ep0 writable), give them
# time to finish FUNCTIONFS_BIND, then rebind the gadget. ffs_func_bind() then
# succeeds, USB enumerates MTP (0x4ee2) + ADB.

G=/config/usb_gadget/g1

# 1) wait for TWRP MtpServer to open ffs.mtp ep0 (up to ~10s)
i=0
while [ $i -lt 100 ]; do
    [ -w /dev/usb-ffs/mtp/ep0 ] && break
    i=$((i+1))
    sleep 0.1
done

# 2) wait for adbd to open ffs.adb ep0 (up to ~10s)
i=0
while [ $i -lt 100 ]; do
    [ -w /dev/usb-ffs/adb/ep0 ] && break
    i=$((i+1))
    sleep 0.1
done

# 3) give daemons time to complete FUNCTIONFS_BIND
sleep 0.5

# 4) rebind gadget: mtp (f1) + adb (f2), MTP product id 0x4ee2
echo 0x18d1 > $G/idVendor 2>/dev/null
echo 0x4ee2 > $G/idProduct 2>/dev/null
echo none > $G/UDC 2>/dev/null
rm $G/configs/b.1/f1 2>/dev/null
rm $G/configs/b.1/f2 2>/dev/null
ln -s $G/functions/ffs.mtp $G/configs/b.1/f1 2>/dev/null
ln -s $G/functions/ffs.adb $G/configs/b.1/f2 2>/dev/null
echo musb-hdrc > $G/UDC 2>/dev/null

exit 0
