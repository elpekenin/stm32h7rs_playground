//! Second-stage bootloader, allowing to jump into STM-DFU,
//! or use UF2

const std = @import("std");

const bootstrap = @import("common/bootstrap.zig");
comptime {
    _ = bootstrap;
}

const stm_dfu = @import("bootloader/stm_dfu.zig");
const uf2 = @import("bootloader/uf2.zig");

const fatfs = @import("fatfs");
const board = @import("common/board.zig");
const sd = @import("common/fatfs_bindings/sd.zig");

// requires pointer stability
var global_fs: fatfs.FileSystem = undefined;

// requires pointer stability
var sd_disk: sd.Disk = .{
    .sd = board.SD,
};

pub fn run() noreturn {
    // button pressed on boot => STM DFU
    if (stm_dfu.check()) {
        std.log.debug("Jumping to STM-DFU", .{});
        return stm_dfu.jump();
    }

    // double press, or app code setting sentinel + reset => UF2 bootloader
    if (uf2.check()) {
        std.log.debug("Jumping to UF2 bootloader", .{});
        uf2.clear_flag();
        return uf2.main();
    }

    // give chance for a double reset into bootloader
    uf2.chance();

    // jump to user code
    std.log.debug("Jumping to application", .{});
    fatfs.disks[0] = &sd_disk.interface;

    {
        global_fs.mount("0:/", true) catch std.debug.panic("Could not mount.", .{});

        defer fatfs.FileSystem.unmount("0:/") catch std.debug.panic("Could not unmount.", .{});

        var file = fatfs.File.open("0:/test.txt", .{
            .mode = .open_append,
            .access = .write_only,
        }) catch std.debug.panic("Could not open file.", .{});
        defer file.close();

        const bytes: [4]u8 = .{ 'A', 'C', 'A', 'B' };
        _ = file.write(&bytes) catch std.debug.panic("Could not write", .{});
    }

    return uf2.app_jump();
}

const logging = @import("common/logging.zig");
pub const std_options = logging.std_options;

const panic_ = @import("common/panic.zig");
pub const panic = panic_.panic;
