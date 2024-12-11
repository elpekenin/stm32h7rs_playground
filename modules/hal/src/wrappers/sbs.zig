const std = @import("std");
const hal = @import("../mod.zig");
const c = hal.c;

pub fn enableIoSpeedOptimize(selection: u32) void {
    c.HAL_SBS_EnableIOSpeedOptimize(selection);
}

pub fn configCompensationCell(selection: u32, code: u32, nmos_value: u32, pmos_value: u32) void {
    c.HAL_SBS_ConfigCompensationCell(selection, code, nmos_value, pmos_value);
}
