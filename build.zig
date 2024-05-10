const std = @import("std");

/// It's not like we get much debug info anyway, lets go for release
/// Results with a couple function calls (.bin size in bytes)
///     - Debug: Flash overflown by 14564
///     - Safe: 19272
///     - Fast: 12528
///     - Small: 11064
const OPTIMIZE: std.builtin.OptimizeMode = .ReleaseFast;

/// `.tiny` is not available for the target :(
const MODEL: std.builtin.CodeModel = .small;

inline fn preprocesor_config(b: *std.Build, compile: *std.Build.Step.Compile) void {
    // for some reason headers from the picolibc step wont be "seen"
    compile.addSystemIncludePath(std.Build.LazyPath{ .cwd_relative = "/usr/include/newlib" });

    const include_paths = .{
        b.path("src/c"), // hal_conf.h
        b.path("lib/cmsis/Include"),
        b.path("lib/CMSIS_5/CMSIS/Core/Include"),
        b.path("lib/hal/Inc"),
    };

    inline for (include_paths) |path| {
        compile.addIncludePath(path);
    }

    inline for (common_c_macros) |macro| {
        compile.root_module.c_macros.append(b.allocator, macro) catch @panic("OOM");
    }
}

/// Make our own libc (picolibc for now) because zig does not provide it for
/// `.freestanding` builds. Then compile it along all of STM's HAL files,
/// and some C stubs needed for a successful build.
fn do_c(b: *std.Build, target: std.Build.ResolvedTarget) *std.Build.Step.Compile {
    const picolibc = b.dependency("picolibc", .{
        .target = target,
        .optimize = OPTIMIZE,
        .tinystdio = true,
    });
    const libc = picolibc.artifact("c");

    const hal = b.addExecutable(.{
        .name = "app.elf",
        .target = target,
        .optimize = OPTIMIZE,
        .code_model = MODEL,
    });
    preprocesor_config(b, hal);

    hal.addCSourceFiles(.{
        .files = hal_src,
        .flags = c_flags,
        .root = b.path("lib/hal/Src"),
    });

    hal.addCSourceFiles(.{
        .files = c_src,
        .flags = c_flags,
        .root = b.path("src/c"),
    });

    hal.linkLibrary(libc);
    hal.setLinkerScript(b.path("ld/app.ld"));

    return hal;
}

/// The actual app, written in zig :)
fn do_zig(b: *std.Build, target: std.Build.ResolvedTarget) *std.Build.Step.Compile {
    const app = b.addStaticLibrary(.{
        .name = "zig",
        .root_source_file = b.path("src/zig/app.zig"),
        .target = target,
        .optimize = OPTIMIZE,
        .code_model = MODEL,
    });
    preprocesor_config(b, app);

    return app;
}

/// Put everything together
pub fn build(b: *std.Build) !void {
    // Targetting ARM Cortex-M7 with no OS.
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .thumb,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m7 },
        .os_tag = .freestanding,
        .abi = .eabihf,
    });

    // Compile all the code
    const c = do_c(b, target);
    const zig = do_zig(b, target);

    // Link everything together
    c.linkLibrary(zig);

    // Convert the output (`.elf`) to what we need (`.bin`)
    const elf = b.addInstallArtifact(c, .{});
    b.default_step.dependOn(&elf.step);

    const elf2bin = b.addObjCopy(c.getEmittedBin(), .{ .format = .bin });
    elf2bin.step.dependOn(&elf.step);

    const bin = b.addInstallBinFile(elf2bin.getOutput(), "app.bin");
    b.default_step.dependOn(&bin.step);
}

// TODO: check those template files
const hal_src = &.{
    "stm32h7rsxx_hal_mmc.c",
    "stm32h7rsxx_hal_dts.c",
    "stm32h7rsxx_hal_pka.c",
    "stm32h7rsxx_ll_lptim.c",
    "stm32h7rsxx_hal_mdios.c",
    "stm32h7rsxx_hal_smbus_ex.c",
    "stm32h7rsxx_ll_fmc.c",
    "stm32h7rsxx_ll_gpio.c",
    "stm32h7rsxx_hal_cec.c",
    "stm32h7rsxx_hal_flash_ex.c",
    "stm32h7rsxx_ll_sdmmc.c",
    "stm32h7rsxx_hal_spi_ex.c",
    "stm32h7rsxx_hal_exti.c",
    "stm32h7rsxx_hal_lptim.c",
    "stm32h7rsxx_hal_hash.c",
    "stm32h7rsxx_hal_rng.c",
    "stm32h7rsxx_hal_xspi.c",
    "stm32h7rsxx_ll_exti.c",
    "stm32h7rsxx_ll_i2c.c",
    "stm32h7rsxx_hal_rtc.c",
    "stm32h7rsxx_ll_rtc.c",
    "stm32h7rsxx_hal_adc_ex.c",
    "stm32h7rsxx_hal_spi.c",
    "stm32h7rsxx_hal_gfxmmu.c",
    "stm32h7rsxx_hal_dma.c",
    "stm32h7rsxx_ll_utils.c",
    "stm32h7rsxx_util_i3c.c",
    "stm32h7rsxx_hal_smbus.c",
    "stm32h7rsxx_hal_rcc.c",
    "stm32h7rsxx_ll_dma.c",
    "stm32h7rsxx_hal_crc.c",
    "stm32h7rsxx_ll_adc.c",
    "stm32h7rsxx_ll_rcc.c",
    "stm32h7rsxx_hal_dcmipp.c",
    "stm32h7rsxx_hal_cortex.c",
    "stm32h7rsxx_hal_smartcard.c",
    "stm32h7rsxx_hal_gpio.c",
    "stm32h7rsxx_hal_pwr.c",
    "stm32h7rsxx_hal_gfxtim.c",
    "stm32h7rsxx_hal_uart_ex.c",
    "stm32h7rsxx_hal_sdram.c",
    "stm32h7rsxx_hal_crc_ex.c",
    "stm32h7rsxx_ll_crc.c",
    "stm32h7rsxx_ll_usart.c",
    "stm32h7rsxx_hal_mce.c",
    "stm32h7rsxx_ll_cordic.c",
    "stm32h7rsxx_hal_sram.c",
    "stm32h7rsxx_hal_sai.c",
    "stm32h7rsxx_hal_mdf.c",
    "stm32h7rsxx_ll_ucpd.c",
    "stm32h7rsxx_hal_cryp.c",
    "stm32h7rsxx_ll_dma2d.c",
    "stm32h7rsxx_ll_rng.c",
    "stm32h7rsxx_hal_cordic.c",
    "stm32h7rsxx_hal_fdcan.c",
    "stm32h7rsxx_hal_dma2d.c",
    "stm32h7rsxx_hal_irda.c",
    "stm32h7rsxx_hal_pcd_ex.c",
    "stm32h7rsxx_hal_i2s_ex.c",
    "stm32h7rsxx_hal_i2c_ex.c",
    "stm32h7rsxx_hal_i2s.c",
    "stm32h7rsxx_hal_dma_ex.c",
    "stm32h7rsxx_hal_nor.c",
    "stm32h7rsxx_hal_gpu2d.c",
    "stm32h7rsxx_hal_ltdc.c",
    "stm32h7rsxx_hal_cryp_ex.c",
    "stm32h7rsxx_ll_crs.c",
    "stm32h7rsxx_hal_sai_ex.c",
    "stm32h7rsxx_hal_sd.c",
    "stm32h7rsxx_hal_ltdc_ex.c",
    "stm32h7rsxx_hal_sd_ex.c",
    "stm32h7rsxx_ll_tim.c",
    "stm32h7rsxx_hal_pcd.c",
    "stm32h7rsxx_hal_i3c.c",
    "stm32h7rsxx_hal_tim_ex.c",
    "stm32h7rsxx_hal_flash.c",
    "stm32h7rsxx_hal_rtc_ex.c",
    "stm32h7rsxx_ll_lpuart.c",
    "stm32h7rsxx_hal_ramecc.c",
    "stm32h7rsxx_hal_icache.c",
    "stm32h7rsxx_ll_usb.c",
    "stm32h7rsxx_hal_eth.c",
    "stm32h7rsxx_hal_smartcard_ex.c",
    "stm32h7rsxx_hal_tim.c",
    "stm32h7rsxx_hal_usart_ex.c",
    "stm32h7rsxx_ll_i3c.c",
    "stm32h7rsxx_hal_i2c.c",
    "stm32h7rsxx_ll_spi.c",
    "stm32h7rsxx_hal.c",
    "stm32h7rsxx_hal_adc.c",
    "stm32h7rsxx_hal_pwr_ex.c",
    "stm32h7rsxx_hal_usart.c",
    "stm32h7rsxx_hal_mmc_ex.c",
    "stm32h7rsxx_hal_nand.c",
    "stm32h7rsxx_ll_pka.c",
    "stm32h7rsxx_ll_dlyb.c",
    "stm32h7rsxx_hal_pssi.c",
    "stm32h7rsxx_hal_jpeg.c",
    "stm32h7rsxx_hal_wwdg.c",
    "stm32h7rsxx_hal_hcd.c",
    "stm32h7rsxx_hal_spdifrx.c",
    "stm32h7rsxx_hal_eth_ex.c",
    "stm32h7rsxx_ll_pwr.c",
    "stm32h7rsxx_hal_rcc_ex.c",
    "stm32h7rsxx_hal_iwdg.c",
    "stm32h7rsxx_hal_rng_ex.c",
    "stm32h7rsxx_hal_uart.c",

    // "stm32h7rsxx_hal_timebase_rtc_wakeup_template.c",
    // "stm32h7rsxx_hal_timebase_tim_template.c",
};

const c_flags = &.{
    "-fno-sanitize=undefined",
};

const c_src = &.{
    "dummy_syscalls.c",
    "interrupt_table.c",
    "system_stm32rsxx.c",
    "stm32h7rsxx_hal_msp.c",
    "stm32h7rsxx_hal_timebase_tim.c",
};

const common_c_macros = &.{
    // prevent CMSIS from providing a defalt entrypoint
    // zig does not properly handle the typedef in a func and C->zig fails
    // ... and we shouldnt need "copy_table_t" or "zero_table_t"
    "-D__PROGRAM_START=_start",

    // needed for a HAL code to be compiled
    // usually defined by STM32IDE (im assuming, not seen on any file)
    "-DSTM32H7S7xx",
    "-DUSE_HAL_DRIVER",
    // "-DUSE_FULL_LL_DRIVER", // for .Debug, but still not working.
};
