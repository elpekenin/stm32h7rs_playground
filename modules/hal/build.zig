const std = @import("std");

const HALCONF = "stm32h7rsxx_hal_conf.h";

// TODO(elpekenin): support to enable/disable callbacks and some other options
const Features = struct {
    const Self = @This();

    adc: bool = false,
    cec: bool = false,
    cordic: bool = false,
    cortex: bool = false,
    crc: bool = false,
    cryp: bool = false,
    dcmipp: bool = false,
    dma: bool = false,
    dma2d: bool = false,
    dts: bool = false,
    eth: bool = false,
    exti: bool = false,
    fdcan: bool = false,
    flash: bool = false,
    gfxmmu: bool = false,
    gfxtim: bool = false,
    gpio: bool = false,
    gpu2d: bool = false,
    hash: bool = false,
    hcd: bool = false,
    i2c: bool = false,
    i2s: bool = false,
    i3c: bool = false,
    icache: bool = false,
    irda: bool = false,
    iwdg: bool = false,
    jpeg: bool = false,
    lptim: bool = false,
    ltdc: bool = false,
    mce: bool = false,
    mdf: bool = false,
    mmc: bool = false,
    nand: bool = false,
    nor: bool = false,
    pcd: bool = false,
    pka: bool = false,
    pssi: bool = false,
    pwr: bool = false,
    ramecc: bool = false,
    rcc: bool = false,
    rng: bool = false,
    rtc: bool = false,
    sai: bool = false,
    sd: bool = false,
    sdram: bool = false,
    smartcard: bool = false,
    smbus: bool = false,
    spdifrx: bool = false,
    spi: bool = false,
    sram: bool = false,
    tim: bool = false,
    uart: bool = false,
    usart: bool = false,
    wwdg: bool = false,
    xspi: bool = false,

    fn fromBuildOptions(b: *std.Build) Self {
        var self = Self{};

        inline for (@typeInfo(Self).Struct.fields) |field| {
            const name = field.name;

            const maybe_val = b.option(
                field.type,
                name,
                "Whether to enable " ++ name,
            );

            if (maybe_val) |val| {
                @field(self, name) = val;
            }
        }

        return self;
    }

    fn toHeader(self: Self, b: *std.Build) *std.Build.Step.ConfigHeader {
        return b.addConfigHeader(
            .{
                .style = .{
                    .cmake = b.path(HALCONF ++ ".in"),
                },
            },
            self,
        );
    }
};

pub fn build(b: *std.Build) !void {
    const features = Features.fromBuildOptions(b);

    const upstream = b.dependency("upstream", .{});
    const cmsis_5 = b.dependency("CMSIS_5", .{});
    const cmsis_device_h7rs = b.dependency("cmsis_device_h7rs", .{});

    const hal = b.addModule(
        "hal",
        .{
            .root_source_file = b.path("src/hal.zig"),
        },
    );

    hal.addCMacro("STM32H7S7xx", "");
    hal.addCMacro("USE_HAL_DRIVER", "");
    hal.addCMacro("__PROGRAM_START", "_start");

    hal.addIncludePath(b.path("include"));
    hal.addIncludePath(upstream.path("Inc"));
    hal.addIncludePath(cmsis_5.path("CMSIS/Core/Include"));
    hal.addIncludePath(cmsis_device_h7rs.path("Include"));

    hal.addConfigHeader(features.toHeader(b));

    hal.addCSourceFile(.{
        .flags = flags,
        .file = b.path("src/system_stm32rsxx.c"),
    });
    hal.addCSourceFiles(.{
        .flags = flags,
        .files = src,
        .root = upstream.path("Src"),
    });
}

const flags = &.{"-fno-sanitize=undefined"};

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
