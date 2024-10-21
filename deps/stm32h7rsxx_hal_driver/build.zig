const std = @import("std");

pub fn build(b: *std.Build) !void {
    // options:
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const dep = b.dependency("upstream", .{});

    const lib = b.addStaticLibrary(.{
        .name = "lib",
        .target = target,
        .optimize = optimize,
    });

    lib.addCSourceFiles(.{
        .files = src,
        .flags = &.{"-fno-sanitize=undefined"},
        .root = dep.path("Src"),
    });

    lib.addIncludePath(dep.path("Inc"));

    lib.installHeadersDirectory(dep.path("Inc"), "", .{});

    const cmsis_5 = b.dependency("CMSIS_5", .{
        .target = target,
        .optimize = optimize,
    }).artifact("lib");
    lib.installLibraryHeaders(cmsis_5);
    lib.linkLibrary(cmsis_5);

    const cmsis_device_h7rs = b.dependency("cmsis_device_h7rs", .{
        .target = target,
        .optimize = optimize,
    }).artifact("lib");
    lib.installLibraryHeaders(cmsis_device_h7rs);
    lib.linkLibrary(cmsis_device_h7rs);

    b.installArtifact(lib);
}

const src = &.{
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
};
