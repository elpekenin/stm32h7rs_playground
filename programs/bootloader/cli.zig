const ushell = @import("ushell");

const commands = @import("cli/commands.zig");

const Commands = union(enum) {
    cat: commands.Cat,
    cd: commands.Cd,
    config: commands.Config,
    echo: commands.Echo,
    led: commands.Led,
    ls: commands.Ls,
    mkdir: commands.Mkdir,
    pwd: commands.Pwd,
    read: commands.Read,
    rm: commands.Rm,
    rmdir: commands.Rmdir,
    reboot: commands.Reboot,
    sleep: commands.Sleep,
    touch: commands.Touch,
    uptime: commands.Uptime,
    version: commands.Version,
    write: commands.Write,
};

pub const Shell = ushell.MakeShell(Commands, .{
    .prompt = "stm32h7s7-dk > ",
    // bigger history size also needs bigger rtt's output buffer to fit all the text
    .max_history_size = 100,
});
