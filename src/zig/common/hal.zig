// "Singleton" C import

const c = @cImport({
    @cInclude("stm32h7rsxx_hal.h");
    @cInclude("stm32h7rsxx_hal_conf.h");
});

pub usingnamespace c;

pub fn early_init() void {
    // Initialize MCU
    c.HAL_MPU_Disable();
    // hal.SCB_EnableICache(); // zig does not like :/
    // hal.SCB_EnableDCache(); // zig does not like :/
    c.SystemCoreClockUpdate();

    const ret = c.HAL_Init();
    if (ret != c.HAL_OK) {
        @panic("HAL initialization failed");
    }
}
