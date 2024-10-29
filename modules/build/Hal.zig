//! Configure STM's HAL generating `stm32h7rsxx_hal_conf.h`
//!   - Enable/disable features
//!   - Enable/disable callbacks

const std = @import("std");
const Self = @This();

// TODO: support some other options

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

pub fn fromArgs(b: *std.Build) Self {
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

pub fn configHeader(self: Self, b: *std.Build) *std.Build.Step.ConfigHeader {
    return b.addConfigHeader(
        .{
            .style = .{
                .cmake = b.path("stm32h7rsxx_hal_conf.h.in"),
            },
        },
        self,
    );
}
