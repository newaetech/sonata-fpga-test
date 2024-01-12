/***********************************************************************
 Copyright (c) 2023-2024, NewAE Technology Inc
 All rights reserved.
 Author: Jean-Pierre Thibault <jpthibault@newae.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

***********************************************************************/


// config and AES:
`define REG_CLKSETTINGS                 8'h00
`define REG_USER_LED                    8'h01
`define REG_CRYPT_TYPE                  8'h02
`define REG_CRYPT_REV                   8'h03
`define REG_IDENTIFY                    8'h04
`define REG_CRYPT_GO                    8'h05
`define REG_CRYPT_TEXTIN                8'h06
`define REG_CRYPT_CIPHERIN              8'h07
`define REG_CRYPT_TEXTOUT               8'h08
`define REG_CRYPT_CIPHEROUT             8'h09
`define REG_CRYPT_KEY                   8'h0a
`define REG_BUILDTIME                   8'h0b
`define REG_DIPS                        8'h0c
`define REG_LEDS                        8'h0d
`define REG_AES_CORES_EN                8'h0e
`define REG_AES_CORE_SEL                8'h0f
`define REG_TURBO                       8'h10
`define REG_ANALOG_DIGITAL              8'h11
`define REG_AES_ALWAYS_ON               8'h12

// hyperram:
`define REG_HYPER_STATUS                8'h83
`define REG_HYPER_RESET                 8'h84
`define REG_LB_MANUAL                   8'h86
`define REG_LB_ERRORS                   8'h87
`define REG_LB_ERROR_ADDR               8'h88
`define REG_LB_STOP_ADDR                8'h89
`define REG_LB_ITERATIONS               8'h8a
`define REG_LB_CURRENT_ADDR             8'h8b
`define REG_BUSY_WAIT                   8'h8c
`define REG_LB_START_ADDR               8'h8d
`define REG_HBMC_ACTION                 8'h8e
`define REG_HBMC_SINGLE_DATA            8'h8f

// XADC:
`define REG_XADC_DRP_ADDR               8'hc0
`define REG_XADC_DRP_DATA               8'hc1
`define REG_XADC_STAT                   8'hc2

// MMCM DRP (AES):
`define REG_MMCM_DRP_ADDR               8'hd0
`define REG_MMCM_DRP_DATA               8'hd1
`define REG_MMCM_DRP_RESET              8'hd2

// MMCM DRP (HyperRAM):
`define REG_MMCM_HR_DRP_ADDR            8'he0
`define REG_MMCM_HR_DRP_DATA            8'he1
`define REG_MMCM_HR_DRP_RESET           8'he2

