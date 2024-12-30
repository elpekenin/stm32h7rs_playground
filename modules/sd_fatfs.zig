//! Bindings to access SD card using fatfs

const hal = @import("hal");
const fatfs = @import("fatfs");

const bsp = hal.bsp;

const mountpoint: [:0]const u8 = "0:/";

const state = struct {
    var init = false;

    /// requires pointer stability
    var global_fs: fatfs.FileSystem = undefined;
    var _disk = SdDisk{}; // requires pointer stability

    var disk: *fatfs.Disk = &_disk.interface;
};

pub fn mount() !void {
    if (state.init) return;

    fatfs.disks[0] = state.disk;
    try state.global_fs.mount(mountpoint, true);

    state.init = true;
}

pub fn cardPresent() bool {
    return state.disk.getStatusFn(state.disk).disk_present;
}

// FatFs's generic API implementation
const SdDisk = struct {
    const Self = @This();

    const sector_size = 512;

    interface: fatfs.Disk = .{
        .getStatusFn = Self.getStatus,
        .initializeFn = Self.initialize,
        .readFn = Self.read,
        .writeFn = Self.write,
        .ioctlFn = Self.ioctl,
    },

    fn getStatus(_: *fatfs.Disk) fatfs.Disk.Status {
        return fatfs.Disk.Status{
            .initialized = bsp.sd.?.initialized(),
            .disk_present = bsp.sd.?.connected(),
            .write_protected = false,
        };
    }

    fn initialize(_: *fatfs.Disk) fatfs.Disk.Error!fatfs.Disk.Status {
        if (bsp.sd == null) {
            return error.DiskNotReady;
        }

        return fatfs.Disk.Status{
            .initialized = bsp.sd.?.initialized(),
            .disk_present = bsp.sd.?.connected(),
            .write_protected = false,
        };
    }

    fn read(_: *fatfs.Disk, buff: [*]u8, sector: fatfs.LBA, count: c_uint) fatfs.Disk.Error!void {
        bsp.sd.?.read(buff, sector, count) catch return error.DiskNotReady;
    }

    fn write(_: *fatfs.Disk, buff: [*]const u8, sector: fatfs.LBA, count: c_uint) fatfs.Disk.Error!void {
        bsp.sd.?.write(buff, sector, count) catch return error.DiskNotReady;
    }

    fn ioctl(interface: *fatfs.Disk, cmd: fatfs.IoCtl, buff: [*]u8) fatfs.Disk.Error!void {
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
