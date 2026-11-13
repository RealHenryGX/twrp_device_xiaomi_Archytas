"""Replace Archytas recovery ramdisk USB files without rebuilding TWRP.

Only Android boot image v1 with a gzip-compressed newc ramdisk is accepted.
The kernel and boot header fields are preserved; the boot ID is recalculated.
"""

import argparse
import gzip
import hashlib
import struct
from pathlib import Path


FILES = {
    "init.recovery.usb.rc": "recovery/root/init.recovery.usb.rc",
    "init.recovery.mt8766.rc": "recovery/root/init.recovery.mt8766.rc",
    "sbin/mtp_rebind.sh": "recovery/root/sbin/mtp_rebind.sh",
}


def align(value, boundary):
    return (value + boundary - 1) // boundary * boundary


def replace_newc(data, replacements):
    offset = 0
    output = bytearray()
    found = set()
    while True:
        header = data[offset : offset + 110]
        if len(header) != 110 or header[:6] not in (b"070701", b"070702"):
            raise ValueError(f"invalid newc header at {offset}")
        fields = [int(header[6 + i * 8 : 14 + i * 8], 16) for i in range(13)]
        size, name_size = fields[6], fields[11]
        name_end = offset + 110 + name_size
        name = data[offset + 110 : name_end]
        if not name.endswith(b"\0"):
            raise ValueError("invalid newc name")
        path = name[:-1].decode("utf-8")
        content_start = align(name_end, 4)
        content_end = content_start + size
        content = data[content_start:content_end]
        if len(content) != size:
            raise ValueError(f"truncated newc entry: {path}")
        if path in replacements:
            content = replacements[path]
            fields[6] = len(content)
            fields[12] = sum(content) & 0xFFFFFFFF if header[:6] == b"070702" else 0
            found.add(path)
        output += header[:6] + b"".join(f"{field:08x}".encode() for field in fields)
        output += name
        output += b"\0" * (align(len(output), 4) - len(output))
        output += content
        output += b"\0" * (align(len(output), 4) - len(output))
        offset = align(content_end, 4)
        if path == "TRAILER!!!":
            break
    if found != replacements.keys():
        raise ValueError(f"ramdisk files missing: {sorted(replacements.keys() - found)}")
    return bytes(output)


def patch(image, replacements):
    if image[:8] != b"ANDROID!":
        raise ValueError("not an Android boot image")
    kernel_size, _, ramdisk_size, _, second_size, _, _, page_size, version, _ = struct.unpack_from(
        "<10I", image, 8
    )
    if version != 1 or second_size != 0 or page_size not in (2048, 4096, 8192, 16384):
        raise ValueError("unsupported boot header or second stage")
    kernel_offset = page_size
    ramdisk_offset = kernel_offset + align(kernel_size, page_size)
    end = ramdisk_offset + align(ramdisk_size, page_size)
    if end != len(image):
        raise ValueError("unexpected image layout or trailing payload")
    kernel = image[kernel_offset : kernel_offset + kernel_size]
    old_ramdisk = image[ramdisk_offset : ramdisk_offset + ramdisk_size]
    if not old_ramdisk.startswith(b"\x1f\x8b"):
        raise ValueError("ramdisk is not gzip")
    original_id = hashlib.sha1()
    for payload in (kernel, old_ramdisk, b"", b""):
        original_id.update(payload)
        original_id.update(struct.pack("<I", len(payload)))
    if image[576:596] != original_id.digest():
        raise ValueError("input boot image ID does not match its payload")
    new_cpio = replace_newc(gzip.decompress(old_ramdisk), replacements)
    new_ramdisk = gzip.compress(new_cpio, compresslevel=9, mtime=0)
    result = bytearray(image[:ramdisk_offset])
    result += new_ramdisk
    result += b"\0" * (align(len(result), page_size) - len(result))
    struct.pack_into("<I", result, 16, len(new_ramdisk))
    digest = hashlib.sha1()
    for payload in (kernel, new_ramdisk, b"", b""):
        digest.update(payload)
        digest.update(struct.pack("<I", len(payload)))
    result[576:608] = digest.digest() + b"\0" * 12
    if len(result) > 33554432:
        raise ValueError("patched image exceeds 32 MiB recovery partition")
    if result[page_size : page_size + kernel_size] != kernel:
        raise ValueError("kernel changed during repack")
    return bytes(result)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--tree", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if args.image.resolve() == args.output.resolve():
        parser.error("output must differ from input image")
    replacements = {dest: (args.tree / source).read_bytes() for dest, source in FILES.items()}
    result = patch(args.image.read_bytes(), replacements)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(result)
    print(f"patched {args.output}: {len(result)} bytes, sha256={hashlib.sha256(result).hexdigest()}")


if __name__ == "__main__":
    main()
