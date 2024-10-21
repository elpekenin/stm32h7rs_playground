Learning project on a STM32H7S78-DK

Long-term goal is to write a UF2 bootloader and maybe a keyboard firmware on top to learn low-level stuff and, specially, zig.

# File structure
- `deps` - Building required 3rd-party code with `build.zig`
- `ld` - Linker scripts
---
- `src/c` - Some "glue" code needed for the project to work
  - TODO: Try and migrate `system_stm32rsxx.c` to zig
- `src/zig/common` - Startup code, this is:
  - `crt0.c`-like setup of memory regions and interrupt table
  - zig's panic and logging configuration
- `src/zig/hal` - Tiny zig wrappers on top of STM's C code, and constants to access peripherals on the DK board
- `src/zig/logging` - Utilities to configure program's output. At the time of writing this, SD card (FatFS) and RTT are supported
- `src/zig/bootloader` - (WIP) Implementation of UF2 bootloader, into the external OSPI flash
- `src/zig/application` - (TBD) So far, just a playground for random code ideas
