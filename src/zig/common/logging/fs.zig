// TODO: Low-level SD card for private API

const std = @import("std");

const fatfs = @import("fatfs");

const hal = @import("../../common/hal.zig");
const board = @import("../../common/board.zig");

const MOUNT = "0:/";

// requires pointer stability
var global_fs: fatfs.FileSystem = undefined;

// requires pointer stability
var disk: Disk = .{
    .sd = board.SD,
};

var full_path: [30]u8 = undefined;

pub const Disk = struct {
    const sector_size = 512;

    sd: board.SDType,

    interface: fatfs.Disk = fatfs.Disk{
        .getStatusFn = getStatus,
        .initializeFn = initialize,
        .readFn = read,
        .writeFn = write,
        .ioctlFn = ioctl,
    },

    pub fn getStatus(interface: *fatfs.Disk) fatfs.Disk.Status {
        const self: *Disk = @fieldParentPtr("interface", interface);

        // TODO?: .disk_present based on SD detection

        const ready = self.sd.ready();

        return fatfs.Disk.Status{
            .initialized = ready,
            .disk_present = ready,
            .write_protected = false,
        };
    }

    pub fn initialize(interface: *fatfs.Disk) fatfs.Disk.Error!fatfs.Disk.Status {
        const self: *Disk = @fieldParentPtr("interface", interface);

        if (!self.sd.ready()) {
            self.sd.init() catch return error.DiskNotReady;
        }

        return fatfs.Disk.Status{
            .initialized = true,
            .disk_present = true,
            .write_protected = false,
        };
    }

    pub fn read(interface: *fatfs.Disk, buff: [*]u8, sector: fatfs.LBA, count: c_uint) fatfs.Disk.Error!void {
        if (interface.getStatus().initialized != true) {
            return error.DiskNotReady;
        }

        const self: *Disk = @fieldParentPtr("interface", interface);
        self.sd.read(buff, sector, count) catch return error.DiskNotReady;
    }

    pub fn write(interface: *fatfs.Disk, buff: [*]const u8, sector: fatfs.LBA, count: c_uint) fatfs.Disk.Error!void {
        if (interface.getStatus().initialized != true) {
            return error.DiskNotReady;
        }

        const self: *Disk = @fieldParentPtr("interface", interface);
        self.sd.write(buff, sector, count) catch return error.DiskNotReady;
    }

    pub fn ioctl(interface: *fatfs.Disk, cmd: fatfs.IoCtl, buff: [*]u8) fatfs.Disk.Error!void {
        _ = interface;

        switch (cmd) {
            .sync => return,
            .get_sector_count => {
                const sectors = 32 * 1024 * 1024 / Disk.sector_size;
                buff[0] = sectors & 0xFF; 
                buff[1] = (sectors >> 8) & 0xFF;
            },
            .get_sector_size, .get_block_size => {
                buff[0] = Disk.sector_size & 0xFF; 
                buff[1] = (Disk.sector_size >> 8) & 0xFF;
            },
            
            else => return error.InvalidParameter
        }
    }
};

pub fn log(path: [:0]const u8, bytes: []const u8) !void {
    fatfs.disks[0] = &disk.interface;

    try global_fs.mount(MOUNT, true);
    defer fatfs.FileSystem.unmount(MOUNT) catch std.debug.panic("Failed to unmount.", .{});

    var i: usize = 0;
    var j: usize = 0;
    while (i < MOUNT.len) : (i += 1) {
        full_path[i] = MOUNT[i];
    }
    while (j < path.len) : (j += 1) {
        full_path[i + j] = path.ptr[i];
    }
    full_path[i + j] = 0;

    var file = try fatfs.File.open(@ptrCast(&full_path), .{
        .mode = .open_append,
        .access = .write_only,
    });
    defer file.close();

    _ = try file.write(bytes);
}
