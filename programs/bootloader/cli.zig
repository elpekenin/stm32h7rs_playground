const ushell = @import("ushell");

const Commands = union(enum) {
    cat: @import("cli/commands/Cat.zig"),
    cd: @import("cli/commands/Cd.zig"),
    config: @import("cli/commands/Config.zig"),
    echo: @import("cli/commands/Echo.zig"),
    led: @import("cli/commands/Led.zig"),
    ls: @import("cli/commands/Ls.zig"),
    mkdir: @import("cli/commands/Mkdir.zig"),
    pwd: @import("cli/commands/Pwd.zig"),
    read: @import("cli/commands/Read.zig"),
    reboot: @import("cli/commands/Reboot.zig"),
    rm: @import("cli/commands/Rm.zig"),
    rmdir: @import("cli/commands/Rmdir.zig"),
    sleep: @import("cli/commands/Sleep.zig"),
    stat: @import("cli/commands/Stat.zig"),
    touch: @import("cli/commands/Touch.zig"),
    tree: @import("cli/commands/Tree.zig"),
    uptime: @import("cli/commands/Uptime.zig"),
    version: @import("cli/commands/Version.zig"),
    write: @import("cli/commands/Write.zig"),
};

pub const Shell = ushell.MakeShell(Commands, .{
    .prompt = "elpekenin@stm32h7s7-dk> ",
    // bigger history size also needs bigger rtt's output buffer to fit all the text
    .max_history_size = 10,
    .parser_options = .{
        .max_tokens = 20,
    },
});
