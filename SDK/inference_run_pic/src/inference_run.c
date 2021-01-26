/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xparameters.h"
#include "xparameters_ps.h"
#include "xil_printf.h"
#include "xil_io.h"
#include <string.h>
#include <stdbool.h>
#include <stdint.h>

#include "conv1_wght.hpp"
#include "conv2_wght.hpp"
#include "fc1_wght.hpp"
#include "fc2_wght.hpp"
#include "ref_pic.hpp"

#define DDR_BASEADDR    XPAR_DDR_MEM_BASEADDR + 0x10000000
#define IFMAP_BASEADDR  XPAR_DDR_MEM_BASEADDR + 0x16000000
#define STATUS_FLAGS    XPAR_DNN_ACCELERATE_SYSTEM_0_BASEADDR + 0x00000000
#define OP_CTRL         XPAR_DNN_ACCELERATE_SYSTEM_0_BASEADDR + 0x00000008
#define BURST_CTRL      XPAR_DNN_ACCELERATE_SYSTEM_0_BASEADDR + 0x00000010
#define CONFIG_REGS     XPAR_DNN_ACCELERATE_SYSTEM_0_BASEADDR + 0x00000018
volatile u32 *WGHT_DATA = (u32 *) 0x10000000;
volatile u32 *IFMAP_DATA = (u32 *) 0x16000000;

typedef unsigned long long busdata;

busdata op_cmd(bool config_load, bool config_done, bool op_go, bool rst, bool axi_rst)
{
    return (0<<5) | (axi_rst<<4) | (rst<<3) | (op_go<<2) | (config_done<<1) | config_load;
};

busdata config_cmd(bool psum_split_condense, bool padding, unsigned char ifmapR, unsigned char ifmapC, unsigned char ofmapR, unsigned char ofmapC, unsigned char kernelR, unsigned char kernelC, unsigned short inchannel, unsigned char outchannel, unsigned char bias_len, bool maxpooling)
{
    return (maxpooling<<49) | (bias_len<<47) | (outchannel<<42) | (inchannel<<32) | (kernelC<<29) | (kernelR<<26) | (ofmapC<<20) | (ofmapR<<14) | (ifmapC<<8) | (ifmapR<<2) | (padding<<1) | psum_split_condense ;
};

int main()
{
    const int wordbyte=8;
    int i,j;
    int wght_len[4]={82,2406,28432,258};
    int accum_idx[4];
    busdata DLA_cmd;

    init_platform();

    xil_printf("Inference Run Let's GO!\n\r");

    j=0;
    for (i = 0; i < 4; i++)
    {
        accum_idx[i]=j;
        j+=wght_len[i];
    }
    

    //=============================
    //     Data Load In DRAM
    //=============================

    // conv1 weight
    for (i = 0; i < wght_len[0]; i++)
    {
        Xil_Out64(DDR_BASEADDR+(accum_idx[0]+i)*wordbyte,conv1_wght[i]);
    }
    // conv2 weight
    for (i = 0; i < wght_len[1]; i++)
    {
        Xil_Out64(DDR_BASEADDR+(accum_idx[1]+i)*wordbyte,conv2_wght[i]);
    }
    // fc1 weight
    for (i = 0; i < wght_len[2]; i++)
    {
        Xil_Out64(DDR_BASEADDR+(accum_idx[2]+i)*wordbyte,fc1_wght[i]);
    }    
    // fc2 weight
    for (i = 0; i < wght_len[3]; i++)
    {
        Xil_Out64(DDR_BASEADDR+(accum_idx[3]+i)*wordbyte,fc2_wght[i]);
    }    

    // ref input pic
    for (i = 0; i < 1024; i++)
    {
        Xil_Out64(IFMAP_BASEADDR+i*wordbyte,ref_pic[i]);
    }


    //=============================
    //     Inference Control
    //=============================
    // axi_rst, rst
    DLA_cmd=op_cmd(0,0,0,1,1); 
    Xil_Out64(OP_CTRL,DLA_cmd);

    DLA_cmd=op_cmd(0,0,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);

    // load tile config
    DLA_cmd=op_cmd(1,0,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);

    // config assignment
    DLA_cmd=config_cmd(1,0,32,32,28,28,5,5,1,8,1,0);
    Xil_Out64(CONFIG_REGS,DLA_cmd);

    cleanup_platform();
    return 0;
}
