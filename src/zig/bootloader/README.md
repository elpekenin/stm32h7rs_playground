Features:
  - If USER button is pressed on boot, jump to STM-DFU
  - Access UF2 bootloader double-pressing reset (green LED indicates when you can press it again to access it)
  - Before jumping to user-code (forced to at start of external flash), both external RAM and Flash are init'ed
  - User-code can access bootloader by writing magic flag and restart (effectively the same as double press)

Maybe:
  - Auto-update
