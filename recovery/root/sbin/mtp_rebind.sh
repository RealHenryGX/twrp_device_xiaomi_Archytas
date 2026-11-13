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
# Wait for FunctionFS MTP endpoints (and ADB endpoints when enabled), then
# bind ffs.mtp and ffs.adb to the USB gadget. TWRP serves the MTP protocol
# through /dev/usb-ffs/mtp, not the separate kernel mtp.gs0 interface.

G=/config/usb_gadget/g1

# Wait for TWRP to publish FunctionFS MTP endpoints (up to ~15s).
i=0
while [ $i -lt 150 ]; do
    [ -e /dev/usb-ffs/mtp/ep1 ] && break
    i=$((i+1))
    sleep 0.1
done
[ -e /dev/usb-ffs/mtp/ep1 ] || exit 1

mode=$(getprop sys.usb.config)
case "$mode" in
    mtp,adb)
        i=0
        while [ $i -lt 150 ]; do
            [ "$(getprop sys.usb.ffs.ready)" = 1 ] && [ -e /dev/usb-ffs/adb/ep1 ] && break
            i=$((i+1))
            sleep 0.1
        done
        [ -e /dev/usb-ffs/adb/ep1 ] || exit 1
        product=0x4ee2
        configuration=mtp_adb
        ;;
    mtp)
        product=0x4ee1
        configuration=mtp
        ;;
    *) exit 0 ;;
esac

# Give both FunctionFS daemons time to finish descriptor setup.
sleep 0.5

# Bind the MTP interface to the same FunctionFS endpoints used by TWRP.
echo none > "$G/UDC" 2>/dev/null
rm -f "$G/configs/b.1/f1" "$G/configs/b.1/f2"
echo 0x18d1 > "$G/idVendor"
echo "$product" > "$G/idProduct"
echo "$configuration" > "$G/configs/b.1/strings/0x409/configuration"
ln -s "$G/functions/ffs.mtp" "$G/configs/b.1/f1" || exit 1
if [ "$mode" = mtp,adb ]; then
    ln -s "$G/functions/ffs.adb" "$G/configs/b.1/f2" || exit 1
fi
echo musb-hdrc > "$G/UDC" || exit 1
setprop sys.usb.state "$mode"

exit 0
