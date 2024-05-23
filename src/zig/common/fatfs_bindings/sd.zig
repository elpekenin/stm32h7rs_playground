//! Glue code to make FatFS capable of writing/reading from
//! a SD Card

const std = @import("std");
const hal = @import("../hal.zig");
const fatfs = @import("fatfs");

pub const Disk = struct {
    const sector_size = 512;

    interface: fatfs.Disk = fatfs.Disk{
        .getStatusFn = getStatus,
        .initializeFn = initialize,
        .readFn = read,
        .writeFn = write,
        .ioctlFn = ioctl,
    },

    pub fn getStatus(_: *fatfs.Disk) fatfs.Disk.Status {
        return fatfs.Disk.Status{
            .initialized = hal.zig.sd.is_initialized(),
            .disk_present = hal.zig.sd.is_connected(),
            .write_protected = false,
        };
    }

    pub fn initialize(_: *fatfs.Disk) fatfs.Disk.Error!fatfs.Disk.Status {
        hal.zig.sd.init() catch {};

        return fatfs.Disk.Status{
            .initialized = hal.zig.sd.is_initialized(),
            .disk_present = hal.zig.sd.is_connected(),
            .write_protected = false,
        };
    }

    pub fn read(_: *fatfs.Disk, buff: [*]u8, sector: fatfs.LBA, count: c_uint) fatfs.Disk.Error!void {
        hal.zig.sd.read(buff, sector, count) catch return error.DiskNotReady;
    }

    pub fn write(_: *fatfs.Disk, buff: [*]const u8, sector: fatfs.LBA, count: c_uint) fatfs.Disk.Error!void {
        hal.zig.sd.write(buff, sector, count) catch return error.DiskNotReady;
    }

    pub fn ioctl(interface: *fatfs.Disk, cmd: fatfs.IoCtl, buff: [*]u8) fatfs.Disk.Error!void {
        if (interface.getStatus().initialized != true) {
            return error.DiskNotReady;
        }

        const info = hal.zig.sd.card_info() catch return error.DiskNotReady;

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
                const size = info.LogBlockSize / Disk.sector_size;
                const ptr: [*]u16 = @alignCast(@ptrCast(buff));
                ptr[0] = @intCast(size);
            },

            else => return error.InvalidParameter,
        }
    }
};
