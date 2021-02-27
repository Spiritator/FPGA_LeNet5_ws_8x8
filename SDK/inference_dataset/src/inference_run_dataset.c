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
#include "xil_cache.h"
#include "xtime_l.h"
#include "sleep.h"
#include "xsdps.h"		/* SD device driver */
#include "ff.h"
#include "xplatform_info.h"
#include <string.h>
#include <stdbool.h>
#include <stdint.h>

#include "conv1_wght.hpp"
#include "conv2_wght.hpp"
#include "fc1_wght.hpp"
#include "fc2_wght.hpp"
//#include "dataset_filenames.hpp"

#define DDR_BASEADDR    XPAR_DDR_MEM_BASEADDR + 0x10000000
#define IFMAP_BASEADDR  XPAR_DDR_MEM_BASEADDR + 0x16000000
#define PRED_BASEADDR   XPAR_DDR_MEM_BASEADDR + 0x17000000
#define STATUS_FLAGS    XPAR_DNN_ACCELERATE_SYSTEM_0_BASEADDR + 0x00000000
#define OP_CTRL         XPAR_DNN_ACCELERATE_SYSTEM_0_BASEADDR + 0x00000008
#define BURST_CTRL      XPAR_DNN_ACCELERATE_SYSTEM_0_BASEADDR + 0x00000010
#define CONFIG_REGS     XPAR_DNN_ACCELERATE_SYSTEM_0_BASEADDR + 0x00000018

volatile u32 *WGHT_DATA = (u32 *) 0x10000000;
volatile u32 *IFMAP_DATA = (u32 *) 0x16000000;
volatile u32 *OFMAP_DATA = (u32 *) 0x17000000;

static FIL fil;		/* File object */
static FATFS fatfs;


uint64_t op_cmd(bool config_load, bool config_done, bool op_go, bool rst, bool axi_rst)
{
    return (axi_rst<<4) | (rst<<3) | (op_go<<2) | (config_done<<1) | config_load;
};

uint64_t config_cmd(bool psum_split_condense, bool padding, unsigned char ifmapR, unsigned char ifmapC, unsigned char ofmapR, unsigned char ofmapC, unsigned char kernelR, unsigned char kernelC, unsigned short inchannel, unsigned char outchannel, unsigned char bias_len, bool maxpooling, bool relu, bool tile_order_first, bool tile_order_last)
{
    uint64_t cmdbuf=0;
    cmdbuf= cmdbuf | ((uint64_t)tile_order_last<<52);
    cmdbuf= cmdbuf | ((uint64_t)tile_order_first<<51);
    cmdbuf= cmdbuf | ((uint64_t)relu<<50);
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
    *FSM_comp= (dla_status>>8) & 15;
    *FSM_data= (dla_status>>12) & 15;
};

void predict_print(void)
{
    uint64_t pred0,pred1;
    pred0=Xil_In64(PRED_BASEADDR);
    pred1=Xil_In64(PRED_BASEADDR+8);
    xil_printf("0: %d | 1: %d | 2: %d | 3: %d | 4: %d | 5: %d | 6: %d | 7: %d | 8: %d | 9: %d\n\r",(int8_t)pred0,(int8_t)(pred0>>8),(int8_t)(pred0>>16),(int8_t)(pred0>>24),(int8_t)(pred0>>32),(int8_t)(pred0>>40),(int8_t)(pred0>>48),(int8_t)(pred0>>56),(int8_t)pred1,(int8_t)(pred1>>8));
};

int SD_card_setup()
{
    FRESULT Res;
    BYTE work[FF_MAX_SS];
    /*
	 * To test logical drive 0, Path should be "0:/"
	 * For logical drive 1, Path should be "1:/"
	 */
	TCHAR *Path = "0:/";

	/*
	 * Register volume work area, initialize device
	 */
	Res = f_mount(&fatfs, Path, 0);

	if (Res != FR_OK) {
        xil_printf("SD card mount fail %d\n\r",Res);
		return XST_FAILURE;
	}

	/*
	 * Path - Path to logical driver, 0 - FDISK format.
	 * 0 - Cluster size is automatically determined based on Vol size.
	 */
	Res = f_mkfs(Path, FM_FAT32, 0, work, sizeof work);
	if (Res != FR_OK) {
        xil_printf("mkfs fail %d\n\r",Res);
		return XST_FAILURE;
	}

    return XST_SUCCESS;
}

int read_SD_card_pic(const char *SD_File, int file_byte_offset)
{
    FRESULT Res;
	UINT NumBytesRead;
	u32 FileSize = 8192;
    
    Res = f_open(&fil, SD_File, FA_READ);
	if (Res) { 
        xil_printf("file open fail %d\n\r",Res);
        return XST_FAILURE; 
    }

	// * Pointer to beginning of file .
	Res = f_lseek(&fil, file_byte_offset);
	if (Res) { return XST_FAILURE; }

    // * Read data from file.
	Res = f_read(&fil, (void *)IFMAP_BASEADDR, FileSize, &NumBytesRead);
	if (Res) { 
        xil_printf("read fail\n\r");
        return XST_FAILURE; 
    }

	// * Close file.
	Res = f_close(&fil);
	if (Res) { return XST_FAILURE; }

	return XST_SUCCESS;
};

void inference_op(uint32_t pred_addr)
{
    //=============================
    //    Convolution 1 Tile 0
    //=============================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config assignment
    Xil_Out64(CONFIG_REGS,0x001CA001B5C72081);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x1000000000290001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x1600000004000002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    // check tile done
    while (Xil_In8(STATUS_FLAGS)!=2){}

    //=============================
    //        Offload Ofmap
    //=============================
    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);
    // offload ofmap cmd
    Xil_Out64(BURST_CTRL,0x1600200003100004);
    // offload ofmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check op_done
    while (Xil_In8(STATUS_FLAGS)!=4){}


    //=============================
    //    Convolution 1 Tile 1
    //=============================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x1000014800290001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x1600000004000002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    //=============================
    //        Offload Ofmap
    //=============================
    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);
    // offload ofmap cmd
    Xil_Out64(BURST_CTRL,0x1600388003100004);
    // offload ofmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check op_done
    while (Xil_In8(STATUS_FLAGS)!=4){}


    //=============================
    //    Maxpooling 1 Tile 0
    //=============================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config assignment
    Xil_Out64(CONFIG_REGS,0x001A200848E39C70);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x1600200003100002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    //=============================
    //        Offload Ofmap
    //=============================
    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);
    // offload ofmap cmd
    Xil_Out64(BURST_CTRL,0x1600200000C40004);
    // offload ofmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check op_done
    while (Xil_In8(STATUS_FLAGS)!=4){}

    //=============================
    //    Maxpooling 1 Tile 1
    //=============================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x1600388003100002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    //=============================
    //        Offload Ofmap
    //=============================
    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);
    // offload ofmap cmd
    Xil_Out64(BURST_CTRL,0x1600262000C40004);
    // offload ofmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check op_done
    while (Xil_In8(STATUS_FLAGS)!=4){}


    //=============================
    //    Convolution 2 Tile 0
    //=============================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config assignment
    Xil_Out64(CONFIG_REGS,0x001D4010B4E38E3A);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x1000029003220001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x1600200001880002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    //=============================
    //        Offload Ofmap
    //=============================
    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);
    // offload ofmap cmd
    Xil_Out64(BURST_CTRL,0x1600510001880004);
    // offload ofmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check op_done
    while (Xil_In8(STATUS_FLAGS)!=4){}

    
    //=============================
    //    Convolution 2 Tile 1
    //=============================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x10001BA003220001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x1600200001880002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    //=============================
    //        Offload Ofmap
    //=============================
    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);
    // offload ofmap cmd
    Xil_Out64(BURST_CTRL,0x16005D4001880004);
    // offload ofmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check op_done
    while (Xil_In8(STATUS_FLAGS)!=4){}


    //=============================
    //    Convolution 2 Tile 2
    //=============================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x100034B003220001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x1600200001880002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    //=============================
    //        Offload Ofmap
    //=============================
    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);
    // offload ofmap cmd
    Xil_Out64(BURST_CTRL,0x1600698001880004);
    // offload ofmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check op_done
    while (Xil_In8(STATUS_FLAGS)!=4){}

    
    //=============================
    //    Maxpooling 2 Tile 0
    //=============================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config assignment
    Xil_Out64(CONFIG_REGS,0x001A40104871CE38);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x1600510001880002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    //=============================
    //        Offload Ofmap
    //=============================
    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);
    // offload ofmap cmd
    Xil_Out64(BURST_CTRL,0x1600510000620004);
    // offload ofmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check op_done
    while (Xil_In8(STATUS_FLAGS)!=4){}
    

    //=============================
    //    Maxpooling 2 Tile 1
    //=============================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x16005D4001880002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    //=============================
    //        Offload Ofmap
    //=============================
    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);
    // offload ofmap cmd
    Xil_Out64(BURST_CTRL,0x1600541000620004);
    // offload ofmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check op_done
    while (Xil_In8(STATUS_FLAGS)!=4){}

    
    //=============================
    //    Maxpooling 2 Tile 2
    //=============================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x1600698001880002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    //=============================
    //        Offload Ofmap
    //=============================
    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);
    // offload ofmap cmd
    Xil_Out64(BURST_CTRL,0x1600572000620004);
    // offload ofmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check op_done
    while (Xil_In8(STATUS_FLAGS)!=4){}


    //===============================
    //    Fully-Connected 1 Setup
    //===============================

    //=================================================
    //    Fully-Connected 1 Input Channel A TIle 0
    //=================================================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config assignment
    Xil_Out64(CONFIG_REGS,0x0008A3D824104104);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x10004DC003D90001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x16005100007B0002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);



    //=================================================
    //    Fully-Connected 1 Input Channel B TIle 0
    //=================================================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config assignment
    Xil_Out64(CONFIG_REGS,0x001423D024104104);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x10006C8803D00001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x160054D8007A0002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    //=============================
    //        Offload Ofmap
    //=============================
    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);
    // offload ofmap cmd
    Xil_Out64(BURST_CTRL,0x160075C000020004);
    // check op_done
    while (Xil_In8(STATUS_FLAGS+1)!=176){}
    // offload ofmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);


    //=================================================
    //    Fully-Connected 1 Input Channel A TIle 1
    //=================================================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config assignment
    Xil_Out64(CONFIG_REGS,0x0008A3D824104104);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x10008B0803D90001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x16005100007B0002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);


    //=================================================
    //    Fully-Connected 1 Input Channel B TIle 1
    //=================================================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config assignment
    Xil_Out64(CONFIG_REGS,0x001423D024104104);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x1000A9D003D00001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x160054D8007A0002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    //=============================
    //        Offload Ofmap
    //=============================
    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);
    // offload ofmap cmd
    Xil_Out64(BURST_CTRL,0x160075C800020004);
    // check op_done
    while (Xil_In8(STATUS_FLAGS+1)!=176){}
    // offload ofmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);


    //=================================================
    //    Fully-Connected 1 Input Channel A TIle 2
    //=================================================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config assignment
    Xil_Out64(CONFIG_REGS,0x0008A3D824104104);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x1000C85003D90001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x16005100007B0002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);


    //=================================================
    //    Fully-Connected 1 Input Channel B TIle 2
    //=================================================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config assignment
    Xil_Out64(CONFIG_REGS,0x001423D024104104);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x1000E71803D00001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x160054D8007A0002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    //=============================
    //        Offload Ofmap
    //=============================
    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);
    // offload ofmap cmd
    Xil_Out64(BURST_CTRL,0x160075D000020004);
    // check op_done
    while (Xil_In8(STATUS_FLAGS+1)!=176){}
    // offload ofmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);


    //=================================================
    //    Fully-Connected 1 Input Channel A TIle 3
    //=================================================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config assignment
    Xil_Out64(CONFIG_REGS,0x0008A3D824104104);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x1001059803D90001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x16005100007B0002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);


    //=================================================
    //    Fully-Connected 1 Input Channel B TIle 3
    //=================================================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config assignment
    Xil_Out64(CONFIG_REGS,0x001423D024104104);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x1001246003D00001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x160054D8007A0002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    //=============================
    //        Offload Ofmap
    //=============================
    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);
    // offload ofmap cmd
    Xil_Out64(BURST_CTRL,0x160075D800020004);
    // check op_done
    while (Xil_In8(STATUS_FLAGS+1)!=176){}
    // offload ofmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);


    //=================================================
    //    Fully-Connected 1 Input Channel A TIle 4
    //=================================================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config assignment
    Xil_Out64(CONFIG_REGS,0x0008A3D824104104);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x100142E003D90001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x16005100007B0002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);


    //=================================================
    //    Fully-Connected 1 Input Channel B TIle 4
    //=================================================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config assignment
    Xil_Out64(CONFIG_REGS,0x001423D024104104);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x100161A803D00001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x160054D8007A0002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    //=============================
    //        Offload Ofmap
    //=============================
    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);
    // offload ofmap cmd
    Xil_Out64(BURST_CTRL,0x160075E000020004);
    // check op_done
    while (Xil_In8(STATUS_FLAGS+1)!=176){}
    // offload ofmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);


    //=================================================
    //    Fully-Connected 1 Input Channel A TIle 5
    //=================================================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config assignment
    Xil_Out64(CONFIG_REGS,0x0008A3D824104104);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x1001802803D90001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x16005100007B0002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);


    //=================================================
    //    Fully-Connected 1 Input Channel B TIle 5
    //=================================================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config assignment
    Xil_Out64(CONFIG_REGS,0x001423D024104104);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x10019EF003D00001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x160054D8007A0002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    //=============================
    //        Offload Ofmap
    //=============================
    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);
    // offload ofmap cmd
    Xil_Out64(BURST_CTRL,0x160075E800020004);
    // check op_done
    while (Xil_In8(STATUS_FLAGS+1)!=176){}
    // offload ofmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);


    //=================================================
    //    Fully-Connected 1 Input Channel A TIle 6
    //=================================================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config assignment
    Xil_Out64(CONFIG_REGS,0x0008A3D824104104);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x1001BD7003D90001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x16005100007B0002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);


    //=================================================
    //    Fully-Connected 1 Input Channel B TIle 6
    //=================================================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config assignment
    Xil_Out64(CONFIG_REGS,0x001423D024104104);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x1001DC3803D00001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x160054D8007A0002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    //=============================
    //        Offload Ofmap
    //=============================
    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);
    // offload ofmap cmd
    Xil_Out64(BURST_CTRL,0x160075F000020004);
    // check op_done
    while (Xil_In8(STATUS_FLAGS+1)!=176){}
    // offload ofmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);


    //=================================================
    //    Fully-Connected 1 Input Channel A TIle 7
    //=================================================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config assignment
    Xil_Out64(CONFIG_REGS,0x0008A3D824104104);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x1001FAB803D90001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x16005100007B0002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);


    //=================================================
    //    Fully-Connected 1 Input Channel B TIle 7
    //=================================================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config assignment
    Xil_Out64(CONFIG_REGS,0x001423D024104104);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x1002198003D00001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x160054D8007A0002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    //=============================
    //        Offload Ofmap
    //=============================
    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);
    // offload ofmap cmd
    Xil_Out64(BURST_CTRL,0x160075F800020004);
    // check op_done
    while (Xil_In8(STATUS_FLAGS+1)!=176){}
    // offload ofmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);


    //=================================================
    //    Fully-Connected 1 Input Channel A TIle 8
    //=================================================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config assignment
    Xil_Out64(CONFIG_REGS,0x0008A3D824104104);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x1002380003D90001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x16005100007B0002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);


    //=================================================
    //    Fully-Connected 1 Input Channel B TIle 8
    //=================================================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config assignment
    Xil_Out64(CONFIG_REGS,0x001423D024104104);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x100256C803D00001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x160054D8007A0002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    //=============================
    //        Offload Ofmap
    //=============================
    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);
    // offload ofmap cmd
    Xil_Out64(BURST_CTRL,0x1600760000020004);
    // check op_done
    while (Xil_In8(STATUS_FLAGS+1)!=176){}
    // offload ofmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);


    //=================================================
    //    Fully-Connected 1 Input Channel A TIle 9
    //=================================================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config assignment
    Xil_Out64(CONFIG_REGS,0x0008A3D824104104);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x1002754803D90001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x16005100007B0002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);


    //=================================================
    //    Fully-Connected 1 Input Channel B TIle 9
    //=================================================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config assignment
    Xil_Out64(CONFIG_REGS,0x001423D024104104);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x1002941003D00001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x160054D8007A0002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    //=============================
    //        Offload Ofmap
    //=============================
    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);
    // offload ofmap cmd
    Xil_Out64(BURST_CTRL,0x1600760800020004);
    // check op_done
    while (Xil_In8(STATUS_FLAGS+1)!=176){}
    // offload ofmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);


    //=================================================
    //    Fully-Connected 1 Input Channel A TIle 10
    //=================================================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config assignment
    Xil_Out64(CONFIG_REGS,0x0008A3D824104104);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x1002B29003D90001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x16005100007B0002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);


    //=================================================
    //    Fully-Connected 1 Input Channel B TIle 10
    //=================================================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config assignment
    Xil_Out64(CONFIG_REGS,0x001423D024104104);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x1002D15803D00001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x160054D8007A0002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    //=============================
    //        Offload Ofmap
    //=============================
    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);
    // offload ofmap cmd
    Xil_Out64(BURST_CTRL,0x1600761000020004);
    // check op_done
    while (Xil_In8(STATUS_FLAGS+1)!=176){}
    // offload ofmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);


    //=================================================
    //    Fully-Connected 1 Input Channel A TIle 11
    //=================================================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config assignment
    Xil_Out64(CONFIG_REGS,0x0008A3D824104104);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x1002EFD803D90001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x16005100007B0002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);


    //=================================================
    //    Fully-Connected 1 Input Channel B TIle 11
    //=================================================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config assignment
    Xil_Out64(CONFIG_REGS,0x001423D024104104);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x10030EA003D00001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x160054D8007A0002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    //=============================
    //        Offload Ofmap
    //=============================
    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);
    // offload ofmap cmd
    Xil_Out64(BURST_CTRL,0x1600761800020004);
    // check op_done
    while (Xil_In8(STATUS_FLAGS+1)!=176){}
    // offload ofmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);


    //=================================================
    //    Fully-Connected 1 Input Channel A TIle 12
    //=================================================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config assignment
    Xil_Out64(CONFIG_REGS,0x0008A3D824104104);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x10032D2003D90001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x16005100007B0002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);


    //=================================================
    //    Fully-Connected 1 Input Channel B TIle 12
    //=================================================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config assignment
    Xil_Out64(CONFIG_REGS,0x001423D024104104);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x10034BE803D00001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x160054D8007A0002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    //=============================
    //        Offload Ofmap
    //=============================
    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);
    // offload ofmap cmd
    Xil_Out64(BURST_CTRL,0x1600762000020004);
    // check op_done
    while (Xil_In8(STATUS_FLAGS+1)!=176){}
    // offload ofmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);


    //=================================================
    //    Fully-Connected 1 Input Channel A TIle 13
    //=================================================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config assignment
    Xil_Out64(CONFIG_REGS,0x0008A3D824104104);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x10036A6803D90001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x16005100007B0002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);


    //=================================================
    //    Fully-Connected 1 Input Channel B TIle 13
    //=================================================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config assignment
    Xil_Out64(CONFIG_REGS,0x001423D024104104);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x1003893003D00001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x160054D8007A0002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    //=============================
    //        Offload Ofmap
    //=============================
    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);
    // offload ofmap cmd
    Xil_Out64(BURST_CTRL,0x1600762800020004);
    // check op_done
    while (Xil_In8(STATUS_FLAGS+1)!=176){}
    // offload ofmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);


    //=================================================
    //    Fully-Connected 1 Input Channel A TIle 14
    //=================================================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config assignment
    Xil_Out64(CONFIG_REGS,0x0008A3D824104104);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x1003A7B003D90001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x16005100007B0002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);


    //=================================================
    //    Fully-Connected 1 Input Channel B TIle 14
    //=================================================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config assignment
    Xil_Out64(CONFIG_REGS,0x001423D024104104);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x1003C67803D00001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x160054D8007A0002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    //=============================
    //        Offload Ofmap
    //=============================
    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);
    // offload ofmap cmd
    Xil_Out64(BURST_CTRL,0x1600763000020004);
    // check op_done
    while (Xil_In8(STATUS_FLAGS+1)!=176){}
    // offload ofmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);


    //=================================================
    //    Fully-Connected 1 Input Channel A TIle 15
    //=================================================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config assignment
    Xil_Out64(CONFIG_REGS,0x0008A3D824104104);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x1003E4F803D90001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x16005100007B0002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);


    //=================================================
    //    Fully-Connected 1 Input Channel B TIle 15
    //=================================================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config assignment
    Xil_Out64(CONFIG_REGS,0x001423D024104104);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x100403C003D00001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x160054D8007A0002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    //=============================
    //        Offload Ofmap
    //=============================
    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);
    // offload ofmap cmd
    Xil_Out64(BURST_CTRL,0x1600763800020004);
    // check op_done
    while (Xil_In8(STATUS_FLAGS+1)!=176){}
    // offload ofmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);

    
    //==========================
    //    Fully-Connected 2 
    //==========================
    //=============================
    //     Configuration Set
    //=============================
    // load tile config
    Xil_Out64(OP_CTRL,0x0000000000000001);
    // config assignment
    Xil_Out64(CONFIG_REGS,0x0019288024104104);
    // config done
    Xil_Out64(OP_CTRL,0x0000000000000002);
    Xil_Out64(OP_CTRL,0x0000000000000000);

    //=============================
    //        Load Weight
    //=============================
    // load weight cmd
    Xil_Out64(BURST_CTRL,0x1004224001020001);
    // load weight cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 3 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=3){}

    //=============================
    //        Load Ifmap
    //=============================
    // load ifmap cmd
    Xil_Out64(BURST_CTRL,0x160075C000100002);
    // load ifmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);
    // check comp 8 data 0
    while (Xil_In8(STATUS_FLAGS+1)!=8){}

    //=============================
    //        Operation Go
    //=============================
    // op_go 
    Xil_Out64(OP_CTRL,0x0000000000000004);
    while (Xil_In8(STATUS_FLAGS)!=2){}

    //=============================
    //        Offload Ofmap
    //=============================
    // op_go cmd lift
    Xil_Out64(OP_CTRL,0x0000000000000000);
    // offload ofmap cmd
    Xil_Out32(BURST_CTRL+4,pred_addr);
    Xil_Out32(BURST_CTRL,0x00020004);
    // check op_done
    while (Xil_In8(STATUS_FLAGS+1)!=176){}
    // offload ofmap cmd lift
    Xil_Out64(BURST_CTRL,0x1000000000010000);


};

int main()
{
    const int wordbyte=8;
    int i,j,cnt=0;
    int wght_len[4]={82,2406,31376,258};
    int fmap_len[4]={1024,1568,1176,16};
    int fmap_idx[4]={1024,0,0,0};
    int wght_idx[4];
    // uint64_t DLA_status;

    int SD_Status;
    char filenameiter[8];

    init_platform();
    Xil_DCacheDisable();

    xil_printf("\n\nInference Run Let's GO!\n\r");

    j=0;
    for (i = 0; i < 4; i++)
    {
        wght_idx[i]=j;
        j+=wght_len[i];
    }
    for (i = 1; i < 4; i++)
    {
        fmap_idx[i]=fmap_idx[i-1]+fmap_len[i];
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
    


    //=============================
    //       Setup SD Card
    //=============================
    SD_Status = SD_card_setup();
	if (SD_Status != XST_SUCCESS) 
		xil_printf("SD Setup failed \r\n");


    //=============================
    //        Timer Setup
    //=============================
	XTime tStart, tEnd, tCalib, tExeCycle, tSDCycle;
	XTime tAccum = 0;

	XTime_GetTime(&tStart);
    XTime_GetTime(&tEnd);
    // timer calibration
	tCalib = tEnd - tStart;
	xil_printf("tStart = %d cycle | tEnd = %d cycle | tCalib = %d cycle \n\r", tStart, tEnd, tCalib);


    //=============================
    //     Inference Control
    //=============================
    // axi_rst, rst
    Xil_Out64(OP_CTRL,0x0000000000000018);
    Xil_Out64(OP_CTRL,0x0000000000000000);


    //======================================================
    //         HALT HALT HALT HALT HALT HALT HALT
    //======================================================
    // while(true)
    // {
    //     DLA_status=Xil_In64(STATUS_FLAGS);
    //     xil_printf("DLA status %016llx\r", DLA_status);
    // }

    for (i = 0; i < 500; i++)
    {
        for (j = 0; j < 20; j++)
        {
            //=============================
            //  Read SD Card Input Image
            //=============================
            XTime_GetTime(&tStart);

            sprintf(filenameiter,"%03d.bin",i);
            SD_Status = read_SD_card_pic(filenameiter,j*8192);
            if (SD_Status != XST_SUCCESS) 
                xil_printf("SD Read failed \r\n");
            
            XTime_GetTime(&tEnd);
            tSDCycle = tEnd - tStart - tCalib;
            tAccum += tSDCycle;

            //=============================
            //       Inference Run
            //=============================
            XTime_GetTime(&tStart);

            inference_op(PRED_BASEADDR+cnt*16);

            XTime_GetTime(&tEnd);
            tExeCycle = tEnd - tStart - tCalib;
            tAccum += tExeCycle;
            xil_printf("img%04d SD load %d inference %d cycles \r", cnt, tSDCycle, tExeCycle);

            cnt++;
        }
    }

    //=============================
    //       Print Prediction
    //=============================
    xil_printf("\n\rInference time %lld cycles \n\r", tAccum);

    xil_printf("\n\rInference Done!!!\n\r");

    cleanup_platform();
    return 0;
}
