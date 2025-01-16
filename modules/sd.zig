//! Bindings to access SD card using zfat

const std = @import("std");

const hal = @import("hal");
const zfat = @import("zfat");

const bsp = hal.bsp;

const mountpoint: [:0]const u8 = "0:/";

const state = struct {
    /// requires pointer stability
    var global_fs: zfat.FileSystem = undefined;
    var _disk = SdDisk{}; // requires pointer stability

    var disk: *zfat.Disk = &_disk.interface;
};

pub var mount = std.once(struct {
    fn mount() void {
        zfat.disks[0] = state.disk;
        state.global_fs.mount(mountpoint, true) catch {};
    }
}.mount);

pub fn cardPresent() bool {
    return state.disk.getStatusFn(state.disk).disk_present;
}

// FatFs's generic API implementation
const SdDisk = struct {
    const Self = @This();

    const sector_size = 512;

    interface: zfat.Disk = .{
        .getStatusFn = Self.getStatus,
        .initializeFn = Self.initialize,
        .readFn = Self.read,
        .writeFn = Self.write,
        .ioctlFn = Self.ioctl,
    },

    fn getStatus(_: *zfat.Disk) zfat.Disk.Status {
        return zfat.Disk.Status{
            .initialized = bsp.sd.?.initialized(),
            .disk_present = bsp.sd.?.connected(),
            .write_protected = false,
        };
    }

    fn initialize(_: *zfat.Disk) zfat.Disk.Error!zfat.Disk.Status {
        if (bsp.sd == null) {
            return error.DiskNotReady;
        }

        return zfat.Disk.Status{
            .initialized = bsp.sd.?.initialized(),
            .disk_present = bsp.sd.?.connected(),
            .write_protected = false,
        };
    }

    fn read(_: *zfat.Disk, buff: [*]u8, sector: zfat.LBA, count: c_uint) zfat.Disk.Error!void {
        bsp.sd.?.read(buff, sector, count) catch return error.DiskNotReady;
    }

    fn write(_: *zfat.Disk, buff: [*]const u8, sector: zfat.LBA, count: c_uint) zfat.Disk.Error!void {
        bsp.sd.?.write(buff, sector, count) catch return error.DiskNotReady;
    }

    fn ioctl(interface: *zfat.Disk, cmd: zfat.IoCtl, buff: [*]u8) zfat.Disk.Error!void {
        if (interface.getStatus().initialized != true) {
            return error.DiskNotReady;
        }

        const info = bsp.sd.?.info() catch return error.DiskNotReady;

        switch (cmd) {
            .sync => return,
            .get_sector_count => {
                const sectors = info.LogBlockNbr;
                const ptr: [*]u32 = @alignCast(@ptrCast(buff));
                ptr[0] = sectors;
            },
            .get_sector_size => {
                const size = info.LogBlockSize;
                const ptr: [*]u16 = @alignCast(@ptrCast(buff));
                ptr[0] = @intCast(size);
            },
            .get_block_size => {
                const size = info.LogBlockSize / SdDisk.sector_size;
                const ptr: [*]u16 = @alignCast(@ptrCast(buff));
                ptr[0] = @intCast(size);
            },

            else => return error.InvalidParameter,
        }
    }
};
