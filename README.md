Learning project on a STM32H7S78-DK

Long-term goal is to write a UF2 bootloader and maybe a keyboard firmware on top to learn low-level stuff and, specially, zig.

# File structure
- `modules` - Building blocks
  - `common`: `crt0.c`-like logic
    - Fill data regions and some other initial setup
    - Set up zig's logging and panic
    - Call into main
  - `hal` - STM's vendor HAL + some zig wrappers
- `programs` - Actual "useful" code
  - `application` - (TBD)
  - `bootloader` - (WIP) Implementation of UF2 bootloader, into the external OSPI flash
