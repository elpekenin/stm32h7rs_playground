const std = @import("std");

const stat = std.c.Stat;
const STDIN = 0;
const STDOUT = 1;
const STDERR = 2;

const ssize_t = c_longlong;
const size_t = c_ulonglong;
const off_t = ssize_t;

const c_str = [*:0]u8;

fn putchar(chr: c_char) void {
    _ = chr;
}

export fn read(fd: c_int, buf: [*c]u8,  count: size_t) callconv(.C)ssize_t {
    _ = buf;
    _ = count;

    switch (fd) {
        STDIN => return 0, // stdin, no input implemented
        else => return -1, // dont read from out buffers!
    }
}

export fn write(fd: c_int, buf: [*c]const u8, count: size_t) callconv(.C) ssize_t {
    switch (fd) {
        STDIN => return -1, // dont write into in buffer!
        // TODO: implement output, with some difference between out/err
        else => {
            var i: usize = 0;
            while (i < count) : (i += 1) {
                putchar(buf[i]);
            }

            return i;
        }
    }
}

export fn open(path: c_str, flags: c_int, ...) callconv(.C) c_int {
    _ = path;
    _ = flags;

    return -1;
}

export fn close(fd: c_int) callconv(.C) c_int {
    _ = fd;

    return 0;
}

export fn lseek(fd: c_int, offset: off_t, whence: c_int) callconv(.C) off_t {
    _ = fd;
    _ = offset;
    _ = whence;

    return -1;
}

export fn lseek_64(fd: c_int, offset: off_t, whence: c_int) callconv(.C) off_t {
    return lseek(fd, offset, whence);
}

export fn unlink(path: c_str) callconv(.C) c_int {
    _ = path;

    return 0;
}

// TODO: state type??
export fn fstat(fd: c_int, sbuf: [*c]u8) callconv(.C) c_int {
    _ = fd;
    _ = sbuf;

    return -1;
}

export fn isatty(fd: c_int) callconv(.C) c_int {
    _ = fd;

    return 1;
}