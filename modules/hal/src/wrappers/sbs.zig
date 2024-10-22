const std = @import("std");
const hal = @import("../hal.zig");

pub fn enable_io_speed_optimize(selection: u32) void {
    hal.c.HAL_SBS_EnableIOSpeedOptimize(selection);
}

pub fn config_compensation_cell(selection: u32, code: u32, nmos_value: u32, pmos_value: u32) void {
    hal.c.HAL_SBS_ConfigCompensationCell(selection, code, nmos_value, pmos_value);
}
