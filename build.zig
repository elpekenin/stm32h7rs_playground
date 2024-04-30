const std = @import("std");

/// It's not like we get much debug info anyway, lets go for release
const OPTIMIZE = std.builtin.OptimizeMode.ReleaseFast;

/// `.tiny` is not available for the target :(
const MODEL = std.builtin.CodeModel.small;

/// What are we targetting? ARM Cortex-M7 with no OS.
var TARGET: std.Build.ResolvedTarget = undefined;


/// Some common config for all steps
fn config_common(
    b: *std.Build,
    compile: *std.Build.Step.Compile
) void {
    // prevent CMSIS from providing a defalt entrypoint
    // zig does not properly handle the typedef in a func and C->zig fails
    // ... and we shouldnt need "copy_table_t" or "zero_table_t"
    compile.root_module.addCMacro("__PROGRAM_START", "_start");

    // usually defined by STM32IDE (im assuming, not seen on any file)
    compile.root_module.addCMacro("STM32H7S7xx", "1");

    compile.addIncludePath(b.path(".")); // for STM code to grab hal_conf.h
    compile.addIncludePath(b.path("lib/cmsis/Include"));
    compile.addIncludePath(b.path("lib/CMSIS_5/CMSIS/Core/Include"));
    compile.addIncludePath(b.path("lib/hal/Inc"));
}

/// Define functions used by libc, such as `read` or `write`
fn do_zlibc_stubs(b: *std.Build) *std.Build.Step.Compile {
    const zlibc_stubs = b.addStaticLibrary(.{
        .name = "zlibc_stubs",
        .root_source_file = b.path("stubs/libc.zig"),
        .target = TARGET,
        .optimize = OPTIMIZE,
        .code_model = MODEL,
        .strip = true,
    });

    return zlibc_stubs;
}

/// Make our own libc (picolibc for now) because zig does not provide it for
/// `.freestanding` builds
fn do_libc(b: *std.Build) *std.Build.Step.Compile {
    const picolibc = b.dependency("picolibc", .{
        .target = TARGET
    });
    return picolibc.artifact("c");
}

/// Compile all of STM's HAL files, and a tiny stub to prevent pulling
/// system_stm32h7rsxx.c and its dependency on a .s startup we dont need
fn do_hal(b: *std.Build) *std.Build.Step.Compile {
    const hal = b.addStaticLibrary(.{
        .name = "HAL",
        .target = TARGET,
        .optimize = OPTIMIZE,
        .code_model = MODEL,
        .strip = true,
    });

    config_common(b, hal);

    hal.addCSourceFiles(.{
        .files = hal_src,
        .flags = hal_flags,
        .root = b.path("lib/hal/Src"),
    });

    hal.addCSourceFiles(.{
        .files = &.{"stubs/hal.c"},
        .flags = hal_flags,
    });

    return hal;
}

/// The actual app, written in zig :)
fn do_app(b: *std.Build) *std.Build.Step.Compile {
    const app = b.addExecutable(
        .{
            .name = "app",
            .root_source_file = b.path("src/app.zig"),
            .target = TARGET,
            .optimize = OPTIMIZE,
            .code_model = MODEL,
            .strip = true,
        }
    );
    config_common(b, app);
    app.setLinkerScript(b.path("ld/app.ld"));

    return app;
}


/// Put everything together
pub fn build(b: *std.Build) !void {
    // Solve our query
    TARGET = b.resolveTargetQuery(.{
        .cpu_arch = .thumb,
        .cpu_model = .{.explicit = &std.Target.arm.cpu.cortex_m7},
        .os_tag = .freestanding,
        .abi = .eabi,
    });

    // Compile all the code
    const zlibc_stubs = do_zlibc_stubs(b);
    const libc = do_libc(b);
    const hal = do_hal(b);
    const app = do_app(b);

    // Link everything together
    app.linkLibrary(zlibc_stubs);
    app.linkLibrary(libc);
    app.linkLibrary(hal);

    // Convert the output (`.elf`) to what we need (`.bin`)
    const elf = b.addInstallArtifact(app, .{});
    b.default_step.dependOn(&elf.step);

    const elf2bin = b.addObjCopy(app.getEmittedBin(), .{.format = .bin});
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
    "stm32h7rsxx_hal_msp_template.c",
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
    "stm32h7rsxx_hal_timebase_rtc_wakeup_template.c",
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
    "stm32h7rsxx_hal_timebase_tim_template.c",
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
};

// TODO: this should really grab the headers from libc step and not need host headers...
const hal_flags = &.{
    "-DUSE_HAL_DRIVER", // needed for a proper build
    "-isystem/usr/include/newlib",
};
