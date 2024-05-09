// "Singleton" C import

const hal = @cImport({
    @cInclude("stm32h7rsxx_hal.h");
    @cInclude("stm32h7rsxx_hal_conf.h");
});

pub usingnamespace hal;
