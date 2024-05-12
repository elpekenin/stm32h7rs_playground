const std = @import("std");

const board = @import("../common/board.zig");
const hal = @import("../common/hal.zig");

const ext_flash = @import("ext_flash.zig");

const EntryPoint = struct {
    sp: u32,
    run: *const fn () noreturn,
};

const BUILTIN_ADDR = 0x1FF18000;

const UF2_FLAG = 0xBEBECAFE;
var uf2_var: u32 linksection(".preserve") = undefined;

fn disable_irq() void {
    asm volatile ("cpsid i" ::: "memory");
}

fn enable_irq() void {
    asm volatile ("cpsie i" ::: "memory");
}

fn get_entry_point(address: u32) EntryPoint {
    return @as(*EntryPoint, @ptrFromInt(address)).*;
}

fn set_MSP(address: u32) void {
    asm volatile ("MSR msp, %[msp]"
        :
        : [msp] "r" (address),
    );
}

fn jump_to_application() noreturn {
    const application = get_entry_point(ext_flash.BASE);

    // Setup SP as the first value on external flash
    // aka:  first entry in the interrupt table
    set_MSP(application.sp);

    application.run();
}

fn jump_to_stm_dfu() noreturn {
    disable_irq();

    var SysTick = @as(*hal.SysTick_Type, @ptrFromInt(hal.SysTick_BASE));
    SysTick.CTRL = 0;

    // FIXME: handle this?
    _ = hal.HAL_RCC_DeInit();

    var NVIC = @as(*hal.NVIC_Type, @ptrFromInt(hal.NVIC_BASE));
    for (0..5) |i| {
        NVIC.ICER[i] = 0xFFFFFFFF;
        NVIC.ICPR[i] = 0xFFFFFFFF;
    }

    enable_irq();

    const stm_dfu = get_entry_point(BUILTIN_ADDR);
    set_MSP(stm_dfu.sp);
    stm_dfu.run();
}

fn jump_to_uf2() noreturn {
    std.debug.panic("UF2", .{});

    // while (true) {
    //     // expose USB MSC
    //     // wait for input, break on that scenario
    // }

    // // check family id
    // // ... and start address

    // // if correct, write it to flash

    // // then, load it
    // jump_to_application();
}

// ----------

pub fn run() noreturn {
    hal.early_init();

    board.USER.init_in(.Down);
    if (board.USER.read_in() == hal.GPIO_PIN_SET) {
        // TODO: Short indicator LED here before jumping?
        jump_to_stm_dfu();
    }

    if (uf2_var == UF2_FLAG) {
        uf2_var = 0;
        jump_to_uf2();
    }

    // set up the sentinel value and "notify" over a LED
    uf2_var = UF2_FLAG;
    board.LD1.init_out(.High);
    board.LD1.set_pin(true);

    // during this time, user can reset again so that
    // reseting the board goes into bootloader
    hal.HAL_Delay(500);

    // if user did not press during the timespan,
    // set the variable back to a non-sentinel value
    // and disable the LED
    uf2_var = 0;
    board.LD1.set_pin(false);

    // TODO: Validate if code is correct, somehow, before
    // jumping to it

    // at this point, we just jump to the application code
    // ext_ram.init();
    // ext_flash.init();
    while (true) {
        std.debug.panic("Application", .{});
    }
    jump_to_application();
}
