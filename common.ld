/* Modeled after microzig's linker generation. */

RAM_START = 0x24000000;
RAM_SIZE  = 0x00071C00;

/* Not really a thing on embedded, but logical entrypoint is main */
ENTRY(main)

MEMORY
{
	flash (rx!w) : ORIGIN = FLASH_START, LENGTH = FLASH_SIZE
	ram (w!rx) : ORIGIN = RAM_START, LENGTH = RAM_SIZE

	ITCM (xrw) : ORIGIN = 0x00000000, LENGTH = 0x00010000
	DTCM (rw) : ORIGIN = 0x20000000, LENGTH = 0x00010000
	SRAMAHB (rw)  : ORIGIN = 0x30000000, LENGTH = 0x00008000
	BKPSRAM (rw)  : ORIGIN = 0x38800000, LENGTH = 0x00001000
}

SECTIONS
{
	PROVIDE(stack = ORIGIN(ram) + LENGTH(ram));

	.text : {
		KEEP(*(.vector_table))

		*(.text*)
		*(.rodata*)

		PROVIDE_HIDDEN (__defmt_start = .);
		KEEP (*(.defmt))
		PROVIDE_HIDDEN (__defmt_end = .);
	} >flash

	/* Debug info (unwinding?) */
	/* .ARM.exidx */
	/DISCARD/ : {
		*(.ARM.exidx*)
		*(.ARM.extab*)
		*(.gnu.linkonce.armexidx.*)
	} >flash

	/* Preserved across reset */
	.noinit (NOLOAD) : {
		KEEP(*(.noinit*))
	} >ram

	.data : {
		data_start = .;
		*(.data.*)
		data_end = .;
	} >ram AT>flash

	.bss (NOLOAD) : {
		bss_start = .;
		*(.bss.*)
		bss_end = .;
	} >ram

	data_source = LOADADDR(.data);
}
