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
#define PRED_BASEADDR   XPAR_DDR_MEM_BASEADDR + 0x17000000
#define STATUS_FLAGS    XPAR_DNN_ACCELERATE_SYSTEM_0_BASEADDR + 0x00000000
#define OP_CTRL         XPAR_DNN_ACCELERATE_SYSTEM_0_BASEADDR + 0x00000008
#define BURST_CTRL      XPAR_DNN_ACCELERATE_SYSTEM_0_BASEADDR + 0x00000010
#define CONFIG_REGS     XPAR_DNN_ACCELERATE_SYSTEM_0_BASEADDR + 0x00000018

volatile u32 *WGHT_DATA = (u32 *) 0x10000000;
volatile u32 *IFMAP_DATA = (u32 *) 0x16000000;

uint64_t op_cmd(bool config_load, bool config_done, bool op_go, bool rst, bool axi_rst)
{
    return (axi_rst<<4) | (rst<<3) | (op_go<<2) | (config_done<<1) | config_load;
};

uint64_t config_cmd(bool psum_split_condense, bool padding, unsigned char ifmapR, unsigned char ifmapC, unsigned char ofmapR, unsigned char ofmapC, unsigned char kernelR, unsigned char kernelC, unsigned short inchannel, unsigned char outchannel, unsigned char bias_len, bool maxpooling)
{
    uint64_t cmdbuf=0;
    cmdbuf= cmdbuf | ((uint64_t)maxpooling<<49);
    cmdbuf= cmdbuf | ((uint64_t)bias_len<<47);
    cmdbuf= cmdbuf | ((uint64_t)outchannel<<42);
    cmdbuf= cmdbuf | ((uint64_t)inchannel<<32);
    cmdbuf= cmdbuf | ((uint64_t)kernelC<<29);
    cmdbuf= cmdbuf | ((uint64_t)kernelR<<26);
    cmdbuf= cmdbuf | ((uint64_t)ofmapC<<20);
    cmdbuf= cmdbuf | ((uint64_t)ofmapR<<14);
    cmdbuf= cmdbuf | ((uint64_t)ifmapC<<8);
    cmdbuf= cmdbuf | ((uint64_t)ifmapR<<2);
    cmdbuf= cmdbuf | ((uint64_t)padding<<1);
    cmdbuf= cmdbuf | ((uint64_t)psum_split_condense);

    return cmdbuf;
};

uint64_t burst_cmd(bool wght_load, bool ifmap_load, bool ofmap_offload, unsigned int ctrl_addr, unsigned short ctrl_mst_length)
{
    uint64_t cmdbuf=0;
    cmdbuf= cmdbuf | ((uint64_t)ctrl_mst_length<<16);
    cmdbuf= cmdbuf | ((uint64_t)ctrl_addr<<32);
    cmdbuf= cmdbuf | ((uint64_t)ofmap_offload<<2);
    cmdbuf= cmdbuf | ((uint64_t)ifmap_load<<1);
    cmdbuf= cmdbuf | ((uint64_t)wght_load);

    return cmdbuf;
};

void read_status(uint64_t dla_status, bool* dataload_ready, bool* tile_done, bool* op_done, bool* AXI4_cmdack, bool* AXI4_error, unsigned char* FSM_comp, unsigned char* FSM_data)
{
    *dataload_ready= dla_status & 1;
    *tile_done= dla_status & 2;
    *op_done= dla_status & 4;
    *AXI4_cmdack= dla_status & 8;
    *AXI4_error= dla_status & 16;
    *FSM_comp= (dla_status>>5) & 15;
    *FSM_data= (dla_status>>9) & 15;
};

int main()
{
    const int wordbyte=8;
    int i,j,k;
    int wght_len[4]={82,2406,28432,258};
    int fmap_len[4]={1024,1568,1176,16};
    int fmap_idx[4]={fmap_len[0],0,0,0};
    int wght_idx[4];
    bool dataload_ready=0,tile_done=0,op_done=0,AXI4_cmdack=0,AXI4_error=0;
    unsigned char FSM_comp=0,FSM_data=0;
    uint64_t DLA_cmd,DLA_status;

    init_platform();

    xil_printf("\n\nInference Run Let's GO!\n\r");

    j=0;
    for (i = 0; i < 4; i++)
    {
        wght_idx[i]=j;
        j+=wght_len[i];
    }
    for (i = 1; i < 4; i++)
    {
        k=fmap_len[i];
        fmap_idx[i]=fmap_idx[i-1]+k;
    }
    

    //=============================
    //     Data Load In DRAM
    //=============================

    // conv1 weight
    for (i = 0; i < wght_len[0]; i++)
    {
        Xil_Out64(DDR_BASEADDR+(wght_idx[0]+i)*wordbyte,conv1_wght[i]);
    }
    // conv2 weight
    for (i = 0; i < wght_len[1]; i++)
    {
        Xil_Out64(DDR_BASEADDR+(wght_idx[1]+i)*wordbyte,conv2_wght[i]);
    }
    // fc1 weight
    for (i = 0; i < wght_len[2]; i++)
    {
        Xil_Out64(DDR_BASEADDR+(wght_idx[2]+i)*wordbyte,fc1_wght[i]);
    }    
    // fc2 weight
    for (i = 0; i < wght_len[3]; i++)
    {
        Xil_Out64(DDR_BASEADDR+(wght_idx[3]+i)*wordbyte,fc2_wght[i]);
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
    xil_printf("Op cmd %016llx\n\r", DLA_cmd);

    DLA_cmd=op_cmd(0,0,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);
    xil_printf("Op cmd %016llx\n\r", DLA_cmd);


    //=============================
    //    Convolution 1 Tile 0
    //=============================
    xil_printf("Convolution 1 Tile 0\n\r");
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    DLA_cmd=op_cmd(1,0,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);
    xil_printf("Op cmd %016llx\n\r", DLA_cmd);

    // config assignment
    DLA_cmd=config_cmd(1,0,32,32,28,28,5,5,1,8,1,0);
    Xil_Out64(CONFIG_REGS,DLA_cmd);
    xil_printf("Config cmd %016llx\n\r", DLA_cmd);

    // config done
    DLA_cmd=op_cmd(0,1,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);
    xil_printf("Op cmd %016llx\n\r", DLA_cmd);

    DLA_cmd=op_cmd(0,0,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    DLA_cmd=burst_cmd(1,0,0,DDR_BASEADDR,41);
    Xil_Out64(BURST_CTRL,DLA_cmd);
    xil_printf("Burst cmd %016llx\n\r", DLA_cmd);

    // check AXI4_cmdack
    while (! AXI4_cmdack)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }
    // load weight cmd lift
    DLA_cmd=burst_cmd(0,0,0,DDR_BASEADDR,1);
    Xil_Out64(BURST_CTRL,DLA_cmd);

    // check FSM comp and data
    xil_printf("Load Weight\n\r");
    while (!(FSM_comp==3 && FSM_data==0))
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    DLA_cmd=burst_cmd(0,1,0,IFMAP_BASEADDR,1024);
    Xil_Out64(BURST_CTRL,DLA_cmd);
    xil_printf("Burst cmd %016llx\n\r", DLA_cmd);

    // check AXI4_cmdack
    while (! AXI4_cmdack)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }
    // load ifmap cmd lift
    DLA_cmd=burst_cmd(0,0,0,DDR_BASEADDR,1);
    Xil_Out64(BURST_CTRL,DLA_cmd);

    // check FSM comp and data
    xil_printf("Load Ifmap\n\r");
    while (!(FSM_comp==8 && FSM_data==0))
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
        printf("datald_rdy %d | tile_dn %d | op_dn %d | AXI_cmdack %d | AXI_err %d | FSM_cmp %d | FSM_dt %d \r", dataload_ready, tile_done, op_done, AXI4_cmdack, AXI4_error, FSM_comp, FSM_data);
    }

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    DLA_cmd=op_cmd(0,0,1,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);
    xil_printf("Op cmd %016llx\n\r", DLA_cmd);

    // check tile_done
    xil_printf("Tile Computing\n\r");
    while (! tile_done)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }

    //=============================
    //        Offload Ofmap
    //=============================
    // op_go cmd lift
    DLA_cmd=op_cmd(0,0,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);

    // offload ofmap cmd
    DLA_cmd=burst_cmd(0,0,1,IFMAP_BASEADDR+fmap_idx[0]*wordbyte,784);
    Xil_Out64(BURST_CTRL,DLA_cmd);
    xil_printf("Burst cmd %016llx\n\r", DLA_cmd);

    // check AXI4_cmdack
    while (! AXI4_cmdack)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }
    // offload ofmap cmd lift
    DLA_cmd=burst_cmd(0,0,0,DDR_BASEADDR,1);
    Xil_Out64(BURST_CTRL,DLA_cmd);

    // check FSM comp and data
    xil_printf("Offload Ofmap\n\r");
    while (! op_done)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }


    //=============================
    //    Convolution 1 Tile 1
    //=============================
    xil_printf("Convolution 1 Tile 1\n\r");
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    DLA_cmd=op_cmd(1,0,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);
    xil_printf("Op cmd %016llx\n\r", DLA_cmd);

    // config done
    DLA_cmd=op_cmd(0,1,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);
    xil_printf("Op cmd %016llx\n\r", DLA_cmd);

    DLA_cmd=op_cmd(0,0,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    DLA_cmd=burst_cmd(1,0,0,DDR_BASEADDR+41*wordbyte,41);
    Xil_Out64(BURST_CTRL,DLA_cmd);
    xil_printf("Burst cmd %016llx\n\r", DLA_cmd);

    // check AXI4_cmdack
    while (! AXI4_cmdack)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }
    // load weight cmd lift
    DLA_cmd=burst_cmd(0,0,0,DDR_BASEADDR,1);
    Xil_Out64(BURST_CTRL,DLA_cmd);

    // check FSM comp and data
    xil_printf("Load Weight\n\r");
    while (!(FSM_comp==3 && FSM_data==0))
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    DLA_cmd=burst_cmd(0,1,0,IFMAP_BASEADDR,1024);
    Xil_Out64(BURST_CTRL,DLA_cmd);
    xil_printf("Burst cmd %016llx\n\r", DLA_cmd);

    // check AXI4_cmdack
    while (! AXI4_cmdack)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }
    // load ifmap cmd lift
    DLA_cmd=burst_cmd(0,0,0,DDR_BASEADDR,1);
    Xil_Out64(BURST_CTRL,DLA_cmd);

    // check FSM comp and data
    xil_printf("Load Ifmap\n\r");
    while (!(FSM_comp==8 && FSM_data==0))
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    DLA_cmd=op_cmd(0,0,1,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);
    xil_printf("Op cmd %016llx\n\r", DLA_cmd);

    // check tile_done
    xil_printf("Tile Computing\n\r");
    while (! tile_done)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }

    //=============================
    //        Offload Ofmap
    //=============================
    // op_go cmd lift
    DLA_cmd=op_cmd(0,0,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);

    // offload ofmap cmd
    DLA_cmd=burst_cmd(0,0,1,IFMAP_BASEADDR+(fmap_idx[0]+784)*wordbyte,784);
    Xil_Out64(BURST_CTRL,DLA_cmd);
    xil_printf("Burst cmd %016llx\n\r", DLA_cmd);

    // check AXI4_cmdack
    while (! AXI4_cmdack)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }
    // offload ofmap cmd lift
    DLA_cmd=burst_cmd(0,0,0,DDR_BASEADDR,1);
    Xil_Out64(BURST_CTRL,DLA_cmd);

    // check FSM comp and data
    xil_printf("Offload Ofmap\n\r");
    while (! op_done)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }

    //=============================
    //    Maxpooling 1 Tile 0
    //=============================
    xil_printf("Maxpooling 1 Tile 0\n\r");
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    DLA_cmd=op_cmd(1,0,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);
    xil_printf("Op cmd %016llx\n\r", DLA_cmd);

    // config assignment
    DLA_cmd=config_cmd(0,0,28,28,14,14,2,2,8,8,0,1);
    Xil_Out64(CONFIG_REGS,DLA_cmd);
    xil_printf("Config cmd %016llx\n\r", DLA_cmd);

    // config done
    DLA_cmd=op_cmd(0,1,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);
    xil_printf("Op cmd %016llx\n\r", DLA_cmd);

    DLA_cmd=op_cmd(0,0,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    DLA_cmd=burst_cmd(0,1,0,IFMAP_BASEADDR+fmap_idx[0]*wordbyte,784);
    Xil_Out64(BURST_CTRL,DLA_cmd);
    xil_printf("Burst cmd %016llx\n\r", DLA_cmd);

    // check AXI4_cmdack
    while (! AXI4_cmdack)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
        xil_printf("datald_rdy %d | tile_dn %d | op_dn %d | AXI_cmdack %d | AXI_err %d | FSM_cmp %d | FSM_dt %d \n\r", dataload_ready, tile_done, op_done, AXI4_cmdack, AXI4_error, FSM_comp, FSM_data);
    }
    // load ifmap cmd lift
    DLA_cmd=burst_cmd(0,0,0,DDR_BASEADDR,1);
    Xil_Out64(BURST_CTRL,DLA_cmd);

    DLA_cmd = Xil_In64(CONFIG_REGS);
    xil_printf("Config Regs Read In %016llx\n\r", DLA_cmd);

    // check FSM comp and data
    xil_printf("Load Ifmap\n\r");
    while (!(FSM_comp==8 && FSM_data==0))
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
        xil_printf("datald_rdy %d | tile_dn %d | op_dn %d | AXI_cmdack %d | AXI_err %d | FSM_cmp %d | FSM_dt %d \r", dataload_ready, tile_done, op_done, AXI4_cmdack, AXI4_error, FSM_comp, FSM_data);
    }

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    DLA_cmd=op_cmd(0,0,1,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);
    xil_printf("Op cmd %016llx\n\r", DLA_cmd);

    // check tile_done
    xil_printf("Tile Computing\n\r");
    while (! tile_done)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }

    //=============================
    //        Offload Ofmap
    //=============================
    // op_go cmd lift
    DLA_cmd=op_cmd(0,0,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);

    // offload ofmap cmd
    DLA_cmd=burst_cmd(0,0,1,IFMAP_BASEADDR+fmap_idx[0]*wordbyte,196);
    Xil_Out64(BURST_CTRL,DLA_cmd);
    xil_printf("Burst cmd %016llx\n\r", DLA_cmd);

    // check AXI4_cmdack
    while (! AXI4_cmdack)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }
    // offload ofmap cmd lift
    DLA_cmd=burst_cmd(0,0,0,DDR_BASEADDR,1);
    Xil_Out64(BURST_CTRL,DLA_cmd);

    // check FSM comp and data
    xil_printf("Offload Ofmap\n\r");
    while (! op_done)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }

    //=============================
    //    Maxpooling 1 Tile 1
    //=============================
    xil_printf("Maxpooling 1 Tile 1\n\r");
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    DLA_cmd=op_cmd(1,0,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);
    xil_printf("Op cmd %016llx\n\r", DLA_cmd);

    // config done
    DLA_cmd=op_cmd(0,1,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);
    xil_printf("Op cmd %016llx\n\r", DLA_cmd);

    DLA_cmd=op_cmd(0,0,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    DLA_cmd=burst_cmd(0,1,0,IFMAP_BASEADDR+(fmap_idx[0]+784)*wordbyte,784);
    Xil_Out64(BURST_CTRL,DLA_cmd);
    xil_printf("Burst cmd %016llx\n\r", DLA_cmd);

    // check AXI4_cmdack
    while (! AXI4_cmdack)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }
    // load ifmap cmd lift
    DLA_cmd=burst_cmd(0,0,0,DDR_BASEADDR,1);
    Xil_Out64(BURST_CTRL,DLA_cmd);

    // check FSM comp and data
    xil_printf("Load Ifmap\n\r");
    while (!(FSM_comp==8 && FSM_data==0))
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    DLA_cmd=op_cmd(0,0,1,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);
    xil_printf("Op cmd %016llx\n\r", DLA_cmd);

    // check tile_done
    xil_printf("Tile Computing\n\r");
    while (! tile_done)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }

    //=============================
    //        Offload Ofmap
    //=============================
    // op_go cmd lift
    DLA_cmd=op_cmd(0,0,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);

    // offload ofmap cmd
    DLA_cmd=burst_cmd(0,0,1,IFMAP_BASEADDR+(fmap_idx[0]+196)*wordbyte,196);
    Xil_Out64(BURST_CTRL,DLA_cmd);
    xil_printf("Burst cmd %016llx\n\r", DLA_cmd);

    // check AXI4_cmdack
    while (! AXI4_cmdack)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }
    // offload ofmap cmd lift
    DLA_cmd=burst_cmd(0,0,0,DDR_BASEADDR,1);
    Xil_Out64(BURST_CTRL,DLA_cmd);

    // check FSM comp and data
    xil_printf("Offload Ofmap\n\r");
    while (! op_done)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }


    //=============================
    //    Convolution 2 Tile 0
    //=============================
    xil_printf("Convolution 2 Tile 0\n\r");
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    DLA_cmd=op_cmd(1,0,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);
    xil_printf("Op cmd %016llx\n\r", DLA_cmd);

    // config assignment
    DLA_cmd=config_cmd(0,1,14,14,14,14,5,5,16,16,2,0);
    Xil_Out64(CONFIG_REGS,DLA_cmd);
    xil_printf("Config cmd %016llx\n\r", DLA_cmd);

    // config done
    DLA_cmd=op_cmd(0,1,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);
    xil_printf("Op cmd %016llx\n\r", DLA_cmd);

    DLA_cmd=op_cmd(0,0,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    DLA_cmd=burst_cmd(1,0,0,DDR_BASEADDR+wght_idx[1]*wordbyte,802);
    Xil_Out64(BURST_CTRL,DLA_cmd);
    xil_printf("Burst cmd %016llx\n\r", DLA_cmd);

    // check AXI4_cmdack
    while (! AXI4_cmdack)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }
    // load weight cmd lift
    DLA_cmd=burst_cmd(0,0,0,DDR_BASEADDR,1);
    Xil_Out64(BURST_CTRL,DLA_cmd);

    // check FSM comp and data
    xil_printf("Load Weight\n\r");
    while (!(FSM_comp==3 && FSM_data==0))
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    DLA_cmd=burst_cmd(0,1,0,IFMAP_BASEADDR+fmap_idx[0]*wordbyte,392);
    Xil_Out64(BURST_CTRL,DLA_cmd);
    xil_printf("Burst cmd %016llx\n\r", DLA_cmd);

    // check AXI4_cmdack
    while (! AXI4_cmdack)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }
    // load ifmap cmd lift
    DLA_cmd=burst_cmd(0,0,0,DDR_BASEADDR,1);
    Xil_Out64(BURST_CTRL,DLA_cmd);

    // check FSM comp and data
    xil_printf("Load Ifmap\n\r");
    while (!(FSM_comp==8 && FSM_data==0))
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    DLA_cmd=op_cmd(0,0,1,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);
    xil_printf("Op cmd %016llx\n\r", DLA_cmd);

    // check tile_done
    xil_printf("Tile Computing\n\r");
    while (! tile_done)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }

    //=============================
    //        Offload Ofmap
    //=============================
    // op_go cmd lift
    DLA_cmd=op_cmd(0,0,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);

    // offload ofmap cmd
    DLA_cmd=burst_cmd(0,0,1,IFMAP_BASEADDR+fmap_idx[1]*wordbyte,392);
    Xil_Out64(BURST_CTRL,DLA_cmd);
    xil_printf("Burst cmd %016llx\n\r", DLA_cmd);

    // check AXI4_cmdack
    while (! AXI4_cmdack)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }
    // offload ofmap cmd lift
    DLA_cmd=burst_cmd(0,0,0,DDR_BASEADDR,1);
    Xil_Out64(BURST_CTRL,DLA_cmd);

    // check FSM comp and data
    xil_printf("Offload Ofmap\n\r");
    while (! op_done)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }

    
    //=============================
    //    Convolution 2 Tile 1
    //=============================
    xil_printf("Convolution 2 Tile 1\n\r");
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    DLA_cmd=op_cmd(1,0,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);
    xil_printf("Op cmd %016llx\n\r", DLA_cmd);

    // config done
    DLA_cmd=op_cmd(0,1,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);
    xil_printf("Op cmd %016llx\n\r", DLA_cmd);

    DLA_cmd=op_cmd(0,0,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    DLA_cmd=burst_cmd(1,0,0,DDR_BASEADDR+(wght_idx[1]+802)*wordbyte,802);
    Xil_Out64(BURST_CTRL,DLA_cmd);
    xil_printf("Burst cmd %016llx\n\r", DLA_cmd);

    // check AXI4_cmdack
    while (! AXI4_cmdack)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }
    // load weight cmd lift
    DLA_cmd=burst_cmd(0,0,0,DDR_BASEADDR,1);
    Xil_Out64(BURST_CTRL,DLA_cmd);

    // check FSM comp and data
    xil_printf("Load Weight\n\r");
    while (!(FSM_comp==3 && FSM_data==0))
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    DLA_cmd=burst_cmd(0,1,0,IFMAP_BASEADDR+fmap_idx[0]*wordbyte,392);
    Xil_Out64(BURST_CTRL,DLA_cmd);
    xil_printf("Burst cmd %016llx\n\r", DLA_cmd);

    // check AXI4_cmdack
    while (! AXI4_cmdack)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }
    // load ifmap cmd lift
    DLA_cmd=burst_cmd(0,0,0,DDR_BASEADDR,1);
    Xil_Out64(BURST_CTRL,DLA_cmd);

    // check FSM comp and data
    xil_printf("Load Ifmap\n\r");
    while (!(FSM_comp==8 && FSM_data==0))
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    DLA_cmd=op_cmd(0,0,1,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);
    xil_printf("Op cmd %016llx\n\r", DLA_cmd);

    // check tile_done
    xil_printf("Tile Computing\n\r");
    while (! tile_done)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }

    //=============================
    //        Offload Ofmap
    //=============================
    // op_go cmd lift
    DLA_cmd=op_cmd(0,0,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);

    // offload ofmap cmd
    DLA_cmd=burst_cmd(0,0,1,IFMAP_BASEADDR+(fmap_idx[1]+392)*wordbyte,392);
    Xil_Out64(BURST_CTRL,DLA_cmd);
    xil_printf("Burst cmd %016llx\n\r", DLA_cmd);

    // check AXI4_cmdack
    while (! AXI4_cmdack)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }
    // offload ofmap cmd lift
    DLA_cmd=burst_cmd(0,0,0,DDR_BASEADDR,1);
    Xil_Out64(BURST_CTRL,DLA_cmd);

    // check FSM comp and data
    xil_printf("Offload Ofmap\n\r");
    while (! op_done)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }


    //=============================
    //    Convolution 2 Tile 2
    //=============================
    xil_printf("Convolution 2 Tile 2\n\r");
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    DLA_cmd=op_cmd(1,0,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);
    xil_printf("Op cmd %016llx\n\r", DLA_cmd);

    // config done
    DLA_cmd=op_cmd(0,1,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);
    xil_printf("Op cmd %016llx\n\r", DLA_cmd);

    DLA_cmd=op_cmd(0,0,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    DLA_cmd=burst_cmd(1,0,0,DDR_BASEADDR+(wght_idx[1]+1604)*wordbyte,802);
    Xil_Out64(BURST_CTRL,DLA_cmd);
    xil_printf("Burst cmd %016llx\n\r", DLA_cmd);

    // check AXI4_cmdack
    while (! AXI4_cmdack)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }
    // load weight cmd lift
    DLA_cmd=burst_cmd(0,0,0,DDR_BASEADDR,1);
    Xil_Out64(BURST_CTRL,DLA_cmd);

    // check FSM comp and data
    xil_printf("Load Weight\n\r");
    while (!(FSM_comp==3 && FSM_data==0))
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    DLA_cmd=burst_cmd(0,1,0,IFMAP_BASEADDR+fmap_idx[0]*wordbyte,392);
    Xil_Out64(BURST_CTRL,DLA_cmd);
    xil_printf("Burst cmd %016llx\n\r", DLA_cmd);

    // check AXI4_cmdack
    while (! AXI4_cmdack)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }
    // load ifmap cmd lift
    DLA_cmd=burst_cmd(0,0,0,DDR_BASEADDR,1);
    Xil_Out64(BURST_CTRL,DLA_cmd);

    // check FSM comp and data
    xil_printf("Load Ifmap\n\r");
    while (!(FSM_comp==8 && FSM_data==0))
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    DLA_cmd=op_cmd(0,0,1,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);
    xil_printf("Op cmd %016llx\n\r", DLA_cmd);

    // check tile_done
    xil_printf("Tile Computing\n\r");
    while (! tile_done)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }

    //=============================
    //        Offload Ofmap
    //=============================
    // op_go cmd lift
    DLA_cmd=op_cmd(0,0,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);

    // offload ofmap cmd
    DLA_cmd=burst_cmd(0,0,1,IFMAP_BASEADDR+(fmap_idx[1]+784)*wordbyte,392);
    Xil_Out64(BURST_CTRL,DLA_cmd);
    xil_printf("Burst cmd %016llx\n\r", DLA_cmd);

    // check AXI4_cmdack
    while (! AXI4_cmdack)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }
    // offload ofmap cmd lift
    DLA_cmd=burst_cmd(0,0,0,DDR_BASEADDR,1);
    Xil_Out64(BURST_CTRL,DLA_cmd);

    // check FSM comp and data
    xil_printf("Offload Ofmap\n\r");
    while (! op_done)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }

    
    //=============================
    //    Maxpooling 2 Tile 0
    //=============================
    xil_printf("Maxpooling 2 Tile 0\n\r");
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    DLA_cmd=op_cmd(1,0,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);
    xil_printf("Op cmd %016llx\n\r", DLA_cmd);

    // config assignment
    DLA_cmd=config_cmd(0,0,14,14,7,7,2,2,16,16,0,1);
    Xil_Out64(CONFIG_REGS,DLA_cmd);
    xil_printf("Config cmd %016llx\n\r", DLA_cmd);

    // config done
    DLA_cmd=op_cmd(0,1,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);
    xil_printf("Op cmd %016llx\n\r", DLA_cmd);

    DLA_cmd=op_cmd(0,0,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    DLA_cmd=burst_cmd(0,1,0,IFMAP_BASEADDR+fmap_idx[1]*wordbyte,392);
    Xil_Out64(BURST_CTRL,DLA_cmd);
    xil_printf("Burst cmd %016llx\n\r", DLA_cmd);

    // check AXI4_cmdack
    while (! AXI4_cmdack)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }
    // load ifmap cmd lift
    DLA_cmd=burst_cmd(0,0,0,DDR_BASEADDR,1);
    Xil_Out64(BURST_CTRL,DLA_cmd);

    // check FSM comp and data
    xil_printf("Load Ifmap\n\r");
    while (!(FSM_comp==8 && FSM_data==0))
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    DLA_cmd=op_cmd(0,0,1,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);
    xil_printf("Op cmd %016llx\n\r", DLA_cmd);

    // check tile_done
    xil_printf("Tile Computing\n\r");
    while (! tile_done)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }

    //=============================
    //        Offload Ofmap
    //=============================
    // op_go cmd lift
    DLA_cmd=op_cmd(0,0,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);

    // offload ofmap cmd
    DLA_cmd=burst_cmd(0,0,1,IFMAP_BASEADDR+fmap_idx[1]*wordbyte,98);
    Xil_Out64(BURST_CTRL,DLA_cmd);
    xil_printf("Burst cmd %016llx\n\r", DLA_cmd);

    // check AXI4_cmdack
    while (! AXI4_cmdack)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }
    // offload ofmap cmd lift
    DLA_cmd=burst_cmd(0,0,0,DDR_BASEADDR,1);
    Xil_Out64(BURST_CTRL,DLA_cmd);

    // check FSM comp and data
    xil_printf("Offload Ofmap\n\r");
    while (! op_done)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }
    

    //=============================
    //    Maxpooling 2 Tile 1
    //=============================
    xil_printf("Maxpooling 2 Tile 1\n\r");
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    DLA_cmd=op_cmd(1,0,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);
    xil_printf("Op cmd %016llx\n\r", DLA_cmd);

    // config done
    DLA_cmd=op_cmd(0,1,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);
    xil_printf("Op cmd %016llx\n\r", DLA_cmd);

    DLA_cmd=op_cmd(0,0,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    DLA_cmd=burst_cmd(0,1,0,IFMAP_BASEADDR+(fmap_idx[1]+392)*wordbyte,392);
    Xil_Out64(BURST_CTRL,DLA_cmd);
    xil_printf("Burst cmd %016llx\n\r", DLA_cmd);

    // check AXI4_cmdack
    while (! AXI4_cmdack)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }
    // load ifmap cmd lift
    DLA_cmd=burst_cmd(0,0,0,DDR_BASEADDR,1);
    Xil_Out64(BURST_CTRL,DLA_cmd);

    // check FSM comp and data
    xil_printf("Load Ifmap\n\r");
    while (!(FSM_comp==8 && FSM_data==0))
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    DLA_cmd=op_cmd(0,0,1,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);
    xil_printf("Op cmd %016llx\n\r", DLA_cmd);

    // check tile_done
    xil_printf("Tile Computing\n\r");
    while (! tile_done)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }

    //=============================
    //        Offload Ofmap
    //=============================
    // op_go cmd lift
    DLA_cmd=op_cmd(0,0,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);

    // offload ofmap cmd
    DLA_cmd=burst_cmd(0,0,1,IFMAP_BASEADDR+(fmap_idx[1]+98)*wordbyte,98);
    Xil_Out64(BURST_CTRL,DLA_cmd);
    xil_printf("Burst cmd %016llx\n\r", DLA_cmd);

    // check AXI4_cmdack
    while (! AXI4_cmdack)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }
    // offload ofmap cmd lift
    DLA_cmd=burst_cmd(0,0,0,DDR_BASEADDR,1);
    Xil_Out64(BURST_CTRL,DLA_cmd);

    // check FSM comp and data
    xil_printf("Offload Ofmap\n\r");
    while (! op_done)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }

    
    //=============================
    //    Maxpooling 2 Tile 2
    //=============================
    xil_printf("Maxpooling 2 Tile 2\n\r");
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    DLA_cmd=op_cmd(1,0,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);
    xil_printf("Op cmd %016llx\n\r", DLA_cmd);

    // config done
    DLA_cmd=op_cmd(0,1,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);
    xil_printf("Op cmd %016llx\n\r", DLA_cmd);

    DLA_cmd=op_cmd(0,0,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    DLA_cmd=burst_cmd(0,1,0,IFMAP_BASEADDR+(fmap_idx[1]+784)*wordbyte,392);
    Xil_Out64(BURST_CTRL,DLA_cmd);
    xil_printf("Burst cmd %016llx\n\r", DLA_cmd);

    // check AXI4_cmdack
    while (! AXI4_cmdack)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }
    // load ifmap cmd lift
    DLA_cmd=burst_cmd(0,0,0,DDR_BASEADDR,1);
    Xil_Out64(BURST_CTRL,DLA_cmd);

    // check FSM comp and data
    xil_printf("Load Ifmap\n\r");
    while (!(FSM_comp==8 && FSM_data==0))
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    DLA_cmd=op_cmd(0,0,1,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);
    xil_printf("Op cmd %016llx\n\r", DLA_cmd);

    // check tile_done
    xil_printf("Tile Computing\n\r");
    while (! tile_done)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }

    //=============================
    //        Offload Ofmap
    //=============================
    // op_go cmd lift
    DLA_cmd=op_cmd(0,0,0,0,0);
    Xil_Out64(OP_CTRL,DLA_cmd);

    // offload ofmap cmd
    DLA_cmd=burst_cmd(0,0,1,IFMAP_BASEADDR+(fmap_idx[1]+196)*wordbyte,98);
    Xil_Out64(BURST_CTRL,DLA_cmd);
    xil_printf("Burst cmd %016llx\n\r", DLA_cmd);

    // check AXI4_cmdack
    while (! AXI4_cmdack)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }
    // offload ofmap cmd lift
    DLA_cmd=burst_cmd(0,0,0,DDR_BASEADDR,1);
    Xil_Out64(BURST_CTRL,DLA_cmd);

    // check FSM comp and data
    xil_printf("Offload Ofmap\n\r");
    while (! op_done)
    {
        DLA_status=Xil_In64(STATUS_FLAGS);
        read_status(DLA_status, &dataload_ready, &tile_done, &op_done, &AXI4_cmdack, &AXI4_error, &FSM_comp, &FSM_data);
    }

    
    xil_printf("Inference Done!!!\n\r", DLA_cmd);

    cleanup_platform();
    return 0;
}
