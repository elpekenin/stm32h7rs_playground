const std = @import("std");
const PanicType = @import("modules/common/panic_config.zig").PanicType;

// FIXME: move into hal/build.zig once ConfigHeader dependency works as intended
// TODO: support some other options
const Options = struct {
    const Self = @This();

    // Features
    HAL_MODULE_ENABLED: bool = true,
    HAL_ADC_MODULE_ENABLED: bool = true,
    HAL_CEC_MODULE_ENABLED: bool = true,
    HAL_CORDIC_MODULE_ENABLED: bool = true,
    HAL_CORTEX_MODULE_ENABLED: bool = true,
    HAL_CRC_MODULE_ENABLED: bool = true,
    HAL_CRYP_MODULE_ENABLED: bool = true,
    HAL_DCMIPP_MODULE_ENABLED: bool = true,
    HAL_DMA_MODULE_ENABLED: bool = true,
    HAL_DMA2D_MODULE_ENABLED: bool = true,
    HAL_DTS_MODULE_ENABLED: bool = true,
    HAL_ETH_MODULE_ENABLED: bool = true,
    HAL_EXTI_MODULE_ENABLED: bool = true,
    HAL_FDCAN_MODULE_ENABLED: bool = true,
    HAL_FLASH_MODULE_ENABLED: bool = true,
    HAL_GFXMMU_MODULE_ENABLED: bool = true,
    HAL_GFXTIM_MODULE_ENABLED: bool = true,
    HAL_GPIO_MODULE_ENABLED: bool = true,
    HAL_GPU2D_MODULE_ENABLED: bool = true,
    HAL_HASH_MODULE_ENABLED: bool = true,
    HAL_HCD_MODULE_ENABLED: bool = true,
    HAL_I2C_MODULE_ENABLED: bool = true,
    HAL_I2S_MODULE_ENABLED: bool = true,
    HAL_I3C_MODULE_ENABLED: bool = true,
    HAL_ICACHE_MODULE_ENABLED: bool = true,
    HAL_IRDA_MODULE_ENABLED: bool = true,
    HAL_IWDG_MODULE_ENABLED: bool = true,
    HAL_JPEG_MODULE_ENABLED: bool = true,
    HAL_LPTIM_MODULE_ENABLED: bool = true,
    HAL_LTDC_MODULE_ENABLED: bool = true,
    HAL_MCE_MODULE_ENABLED: bool = true,
    HAL_MDF_MODULE_ENABLED: bool = true,
    HAL_MMC_MODULE_ENABLED: bool = true,
    HAL_NAND_MODULE_ENABLED: bool = true,
    HAL_NOR_MODULE_ENABLED: bool = true,
    HAL_PCD_MODULE_ENABLED: bool = true,
    HAL_PKA_MODULE_ENABLED: bool = true,
    HAL_PSSI_MODULE_ENABLED: bool = true,
    HAL_PWR_MODULE_ENABLED: bool = true,
    HAL_RAMECC_MODULE_ENABLED: bool = true,
    HAL_RCC_MODULE_ENABLED: bool = true,
    HAL_RNG_MODULE_ENABLED: bool = true,
    HAL_RTC_MODULE_ENABLED: bool = true,
    HAL_SAI_MODULE_ENABLED: bool = true,
    HAL_SD_MODULE_ENABLED: bool = true,
    HAL_SDRAM_MODULE_ENABLED: bool = true,
    HAL_SMARTCARD_MODULE_ENABLED: bool = true,
    HAL_SMBUS_MODULE_ENABLED: bool = true,
    HAL_SPDIFRX_MODULE_ENABLED: bool = true,
    HAL_SPI_MODULE_ENABLED: bool = true,
    HAL_SRAM_MODULE_ENABLED: bool = true,
    HAL_TIM_MODULE_ENABLED: bool = true,
    HAL_UART_MODULE_ENABLED: bool = true,
    HAL_USART_MODULE_ENABLED: bool = true,
    HAL_WWDG_MODULE_ENABLED: bool = true,
    HAL_XSPI_MODULE_ENABLED: bool = true,

    // Callbacks
    USE_HAL_ADC_REGISTER_CALLBACKS: bool = false,
    USE_HAL_CEC_REGISTER_CALLBACKS: bool = false,
    USE_HAL_CORDIC_REGISTER_CALLBACKS: bool = false,
    USE_HAL_CRYP_REGISTER_CALLBACKS: bool = false,
    USE_HAL_DCMIPP_REGISTER_CALLBACKS: bool = false,
    USE_HAL_FDCAN_REGISTER_CALLBACKS: bool = false,
    USE_HAL_GFXMMU_REGISTER_CALLBACKS: bool = false,
    USE_HAL_HASH_REGISTER_CALLBACKS: bool = false,
    USE_HAL_I2C_REGISTER_CALLBACKS: bool = false,
    USE_HAL_I2S_REGISTER_CALLBACKS: bool = false,
    USE_HAL_IRDA_REGISTER_CALLBACKS: bool = false,
    USE_HAL_JPEG_REGISTER_CALLBACKS: bool = false,
    USE_HAL_LPTIM_REGISTER_CALLBACKS: bool = false,
    USE_HAL_MDF_REGISTER_CALLBACKS: bool = false,
    USE_HAL_MMC_REGISTER_CALLBACKS: bool = false,
    USE_HAL_NAND_REGISTER_CALLBACKS: bool = false,
    USE_HAL_NOR_REGISTER_CALLBACKS: bool = false,
    USE_HAL_PCD_REGISTER_CALLBACKS: bool = false,
    USE_HAL_PKA_REGISTER_CALLBACKS: bool = false,
    USE_HAL_PSSI_REGISTER_CALLBACKS: bool = false,
    USE_HAL_RNG_REGISTER_CALLBACKS: bool = false,
    USE_HAL_RTC_REGISTER_CALLBACKS: bool = false,
    USE_HAL_SAI_REGISTER_CALLBACKS: bool = false,
    USE_HAL_SD_REGISTER_CALLBACKS: bool = false,
    USE_HAL_SDRAM_REGISTER_CALLBACKS: bool = false,
    USE_HAL_SMARTCARD_REGISTER_CALLBACKS: bool = false,
    USE_HAL_SMBUS_REGISTER_CALLBACKS: bool = false,
    USE_HAL_SPDIFRX_REGISTER_CALLBACKS: bool = false,
    USE_HAL_SPI_REGISTER_CALLBACKS: bool = false,
    USE_HAL_SRAM_REGISTER_CALLBACKS: bool = false,
    USE_HAL_TIM_REGISTER_CALLBACKS: bool = false,
    USE_HAL_UART_REGISTER_CALLBACKS: bool = false,
    USE_HAL_USART_REGISTER_CALLBACKS: bool = false,
    USE_HAL_WWDG_REGISTER_CALLBACKS: bool = false,
    USE_HAL_XSPI_REGISTER_CALLBACKS: bool = false,

    fn fromBuildOptions(b: *std.Build) Self {
        var self = Self{};

        inline for (@typeInfo(Self).Struct.fields) |field| {
            const name = field.name;

            const maybe_val = b.option(field.type, name, "Control `#define` with the same name");

            if (maybe_val) |val| {
                @field(self, name) = val;
            }
        }

        return self;
    }

    fn halconf(self: Self, b: *std.Build) *std.Build.Step.ConfigHeader {
        return b.addConfigHeader(
            .{
                .style = .{
                    .cmake = b.path("stm32h7rsxx_hal_conf.h.in"),
                },
            },
            self,
        );
    }
};

const Program = enum {
    const Self = @This();

    bootloader,
    application,

    fn name(self: Self) []const u8 {
        return switch (self) {
            .bootloader => "bootloader",
            .application => "application",
        };
    }
};

const LibC = enum {
    const Self = @This();

    picolibc,
    foundation,

    fn dependency(self: Self) []const u8 {
        return switch (self) {
            .picolibc => "picolibc",
            .foundation => "foundation",
        };
    }

    fn artifact(self: Self) []const u8 {
        return switch (self) {
            .picolibc => "c",
            .foundation => "foundation",
        };
    }
};

pub fn build(b: *std.Build) !void {
    // *** Build configuration ***
    const program: Program = b.option(
        Program,
        "program",
        "Program to build",
    ) orelse @panic("Select target program");

    const libc: LibC = b.option(
        LibC,
        "libc",
        "LibC implementation to use",
    ) orelse @panic("Select a libc implementation");

    const panic_type: PanicType = b.option(
        PanicType,
        "panic_type",
        "Control panic behavior",
    ) orelse .ToggleLeds;

    const panic_timer: u16 = b.option(
        u16,
        "panic_timer",
        "Control panic behavior",
    ) orelse 500;

    const target = b.resolveTargetQuery(.{
        .cpu_arch = .thumb,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.cortex_m7 },
        .cpu_features_add = std.Target.arm.featureSet(&.{
            // FIXME: which one is correct?
            .vfp4d16,
            // .fp_armv8d16,
        }),
        .os_tag = .freestanding,
        .abi = .eabihf,
    });

    const optimize: std.builtin.OptimizeMode = .ReleaseSmall;

    const hal_options = Options.fromBuildOptions(b);
    const halconf = hal_options.halconf(b);

    // *** Entry point ***
    const start = b.addExecutable(.{
        .name = b.fmt("{s}.elf", .{program.name()}), // STM32CubeProgrammer does not like the lack of extension
        .root_source_file = b.path("modules/common/start.zig"),
        .target = target,
        .optimize = optimize,
        .strip = false,
        .error_tracing = true,
    });
    start.setLinkerScript(b.path(b.fmt("ld/{s}.ld", .{program.name()})));

    // *** Dependencies ***
    const libc_dep = b.dependency(
        libc.dependency(),
        .{
            .target = target,
            .optimize = optimize,
        },
    );
    const libc_lib = libc_dep.artifact(libc.artifact());

    const hal_dep = b.dependency("hal", .{});
    const hal_module = hal_dep.module("hal");

    const rtt_dep = b.dependency("rtt", .{}).module("rtt");

    const zfat_dep = b.dependency(
        "zfat",
        .{
            .target = target,
            .optimize = optimize,
            .@"static-rtc" = @as([]const u8, "2099-01-01"),
            .@"no-libc" = true,
        },
    );
    const zfat_module = zfat_dep.module("zfat");

    // *** zig code ***
    const program_module = b.addModule(
        "program",
        .{
            .root_source_file = b.path(
                b.fmt("modules/{s}/main.zig", .{program.name()}),
            ),
        },
    );

    const logging_module = b.addModule(
        "logging",
        .{
            .root_source_file = b.path("modules/logging/logging.zig"),
        },
    );

    const options = b.addOptions();
    options.addOption(bool, "has_zfat", true);
    options.addOption([]const u8, "app_name", program.name());
    // TODO: Expose to CLI?
    options.addOption(usize, "panic_type", @intFromEnum(panic_type)); // HAL_Delay after iterating all LEDs
    options.addOption(u16, "panic_timer", panic_timer); // HAL_Delay between LEDs
    const options_module = options.createModule();

    // *** Glue together (sorted alphabetically just because) ***
    program_module.addImport("hal", hal_module);
    program_module.addImport("options", options_module);

    hal_module.addConfigHeader(halconf);
    hal_module.linkLibrary(libc_lib);

    libc_lib.link_gc_sections = true;
    libc_lib.link_data_sections = true;
    libc_lib.link_function_sections = true;

    logging_module.addImport("fatfs", zfat_module);
    logging_module.addImport("hal", hal_module);
    logging_module.addImport("options", options_module);
    logging_module.addImport("rtt", rtt_dep);

    start.linkLibrary(libc_lib);
    start.root_module.addImport("program", program_module);
    start.root_module.addImport("hal", hal_module);
    start.root_module.addImport("logging", logging_module);
    start.root_module.addImport("options", options_module);
    start.step.dependOn(&halconf.step); // FIXME: remove hack

    zfat_module.linkLibrary(libc_lib);

    // otherwise it gets optimized away
    start.forceUndefinedSymbol("vector_table");

    // *** Output ***
    b.installArtifact(start);
}
