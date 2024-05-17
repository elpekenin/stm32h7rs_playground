const fatfs = @import("fatfs");

const board = @import("../../../common/board.zig");

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
        if (interface.getStatus().initialized != true) {
            return error.DiskNotReady;
        }

        const self: *Disk = @fieldParentPtr("interface", interface);
        const info = self.sd.card_info() catch return error.DiskNotReady;

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
