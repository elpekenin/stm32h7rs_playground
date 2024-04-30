/* Note: Extracted from system_stm32h7rsxx.c
 * 
 * SystemCoreClock variable was needed, but it also added dependency on 
 * startup files written in assembly, and some symbols which arent defined
 * nor needed, as picolibc is taking care of the bootstraping.
 * 
 */

#include "stm32h7rsxx.h"

#if !defined  (HSE_VALUE)
  #define HSE_VALUE    24000000UL /*!< Value of the High-Speed External oscillator in Hz */
#endif /* HSE_VALUE */

#if !defined  (HSI_VALUE)
  #define HSI_VALUE    64000000UL /*!< Value of the High-Speed Internal oscillator in Hz */
#endif /* HSI_VALUE */

#if !defined  (CSI_VALUE)
  #define CSI_VALUE    4000000UL  /*!< Value of the Low-power Internal oscillator in Hz */
#endif /* CSI_VALUE */

uint32_t SystemCoreClock = HSI_VALUE;
