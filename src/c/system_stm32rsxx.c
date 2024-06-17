/* NOTE: Adapted from cmsis_device_h7rs/Source/Templates/system_stm32h7rsxx.c
 *
 * SystemCoreClock variable was needed, but it also added dependency on 
 * startup files written in assembly, and some symbols which arent defined
 * nor needed, as picolibc is taking care of the bootstraping.
 *
 */

/*
 * Copyright (c) 2022 STMicroelectronics.
 * All rights reserved.
 *
 * This software is licensed under terms that can be found in the LICENSE file
 * in the root directory of this software component.
 * If no LICENSE file comes with this software, it is provided AS-IS.
 *
 ******************************************************************************
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

void SystemCoreClockUpdate(void)
{
    uint32_t sysclk, hsivalue, pllsource, pllm, pllp, core_presc;
    float_t pllfracn, pllvco;

    /* Get SYSCLK source -------------------------------------------------------*/
    switch (RCC->CFGR & RCC_CFGR_SWS) {
    case 0x00:  /* HSI used as system clock source (default after reset) */
        sysclk = (HSI_VALUE >> ((RCC->CR & RCC_CR_HSIDIV) >> RCC_CR_HSIDIV_Pos));
        break;

    case 0x08:  /* CSI used as system clock source */
        sysclk = CSI_VALUE;
        break;

    case 0x10:  /* HSE used as system clock source */
        sysclk = HSE_VALUE;
        break;

    case 0x18:  /* PLL1 used as system clock  source */
        /* PLL1_VCO = (HSE_VALUE or HSI_VALUE or CSI_VALUE/ PLLM) * PLLN
        SYSCLK = PLL1_VCO / PLL1R
        */
        pllsource = (RCC->PLLCKSELR & RCC_PLLCKSELR_PLLSRC);
        pllm = ((RCC->PLLCKSELR & RCC_PLLCKSELR_DIVM1) >> RCC_PLLCKSELR_DIVM1_Pos)  ;
        if ((RCC->PLLCFGR & RCC_PLLCFGR_PLL1FRACEN) != 0U) {
            pllfracn = (float_t)(uint32_t)(((RCC->PLL1FRACR & RCC_PLL1FRACR_FRACN)>> RCC_PLL1FRACR_FRACN_Pos));
        } else {
            pllfracn = (float_t)0U;
        }

        if (pllm != 0U) {
            switch (pllsource) {
            case 0x02:  /* HSE used as PLL1 clock source */
                pllvco = ((float_t)HSE_VALUE / (float_t)pllm) * ((float_t)(uint32_t)(RCC->PLL1DIVR1 & RCC_PLL1DIVR1_DIVN) + (pllfracn/(float_t)0x2000) +(float_t)1 );
                break;

            case 0x01:  /* CSI used as PLL1 clock source */
                pllvco = ((float_t)CSI_VALUE / (float_t)pllm) * ((float_t)(uint32_t)(RCC->PLL1DIVR1 & RCC_PLL1DIVR1_DIVN) + (pllfracn/(float_t)0x2000) +(float_t)1 );
                break;

            case 0x00:  /* HSI used as PLL1 clock source */
            default:
                hsivalue = (HSI_VALUE >> ((RCC->CR & RCC_CR_HSIDIV) >> RCC_CR_HSIDIV_Pos));
                pllvco = ( (float_t)hsivalue / (float_t)pllm) * ((float_t)(uint32_t)(RCC->PLL1DIVR1 & RCC_PLL1DIVR1_DIVN) + (pllfracn/(float_t)0x2000) +(float_t)1 );
                break;
            }
            pllp = (((RCC->PLL1DIVR1 & RCC_PLL1DIVR1_DIVP) >> RCC_PLL1DIVR1_DIVP_Pos) + 1U ) ;
            sysclk =  (uint32_t)(float_t)(pllvco/(float_t)pllp);
        } else {
            sysclk = 0U;
        }
        break;

    default:  /* Unexpected, default to HSI used as system clock source (default after reset) */
        sysclk = (HSI_VALUE >> ((RCC->CR & RCC_CR_HSIDIV) >> RCC_CR_HSIDIV_Pos));
        break;
    }

    /* system clock frequency : CM7 CPU frequency  */
    core_presc = (RCC->CDCFGR & RCC_CDCFGR_CPRE);
    if (core_presc >= 8U) {
        SystemCoreClock = (sysclk >> (core_presc - RCC_CDCFGR_CPRE_3 + 1U));
    } else {
        SystemCoreClock = sysclk;
    }
}