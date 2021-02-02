# -*- coding: utf-8 -*-
"""
Created on Mon Jan 25 14:46:47 2021

@author: Yung-Yu Tsai

RTL verification mem generation and validation

"""

#%% LeNet5 weight stationary 8x8 Vivado Project data prep L1

import numpy as np
import h5py

lenet_intermediate=np.load("lenet_intermediate_hybrid_ovf.npy",allow_pickle=True)
lenet_intermediate=list(lenet_intermediate)
ifmap=lenet_intermediate[0]
ofmap=lenet_intermediate[1]

with h5py.File("mnist_lenet5_weight.h5",'r') as weight_f:
    kernel=weight_f['conv2d_1']['conv2d_1/kernel:0'][()]
    bias=weight_f['conv2d_1']['conv2d_1/bias:0'][()]


bias_in_PE=np.stack(np.split(bias,16/8,axis=-1))
bias_in_PE=np.multiply(bias_in_PE,2**3)
bias_in_PE=np.round(bias_in_PE)
bias_in_PE=bias_in_PE.astype(np.int8)        

kernel_in=np.transpose(kernel,(3,1,0,2))
kernel_in=np.reshape(kernel_in,[16,5*5*1])
kernel_in=np.transpose(kernel_in)
kernel_in_PE=np.stack(np.split(kernel_in,5))
kernel_in_PE=np.pad(kernel_in_PE,((0, 0), (0, 3), (0, 0)),'constant',constant_values=0)
kernel_in_PE=np.stack(np.split(kernel_in_PE,16/8,axis=-1))
kernel_in_PE=np.multiply(kernel_in_PE,2**3)
kernel_in_PE=np.round(kernel_in_PE)
kernel_in_PE=kernel_in_PE.astype(np.int8)

ofmap_out_PE=np.transpose(ofmap,[1,0,2])
ofmap_out_PE=np.reshape(ofmap_out_PE, [784,16])
ofmap_out_PE=np.stack(np.split(ofmap_out_PE, 16/8, axis=-1))
ofmap_out_PE=np.multiply(ofmap_out_PE,2**3)
ofmap_out_PE=ofmap_out_PE.astype(np.int8)        


def preprocess_input_img_mem(img):
    # img shape (28,28,1)
    img_processed=np.pad(img,((2, 2), (2, 2), (0,0)),'constant',constant_values=0)
    img_processed=np.multiply(img_processed,2**3)
    img_processed=img_processed.astype(np.int8)
    
    img_processed=np.transpose(img_processed,[1,0,2])
    img_processed=np.reshape(img_processed, [32*32,1])
    img_processed=np.tile(img_processed,[1,5])
    
    roller=np.array([  0,   1,   2,   3,   4])
    
    for i in range(img_processed.shape[1]):
        img_processed[:,i]=np.roll(img_processed[:,i],-roller[i])
        
    img_processed=np.pad(img_processed,((0, 0), (0, 3)),'constant',constant_values=0)
    
    return img_processed


#%% LeNet5 weight stationary 8x8 Vivado Project textfigure gen memread L1

ifmap_in_mem=preprocess_input_img_mem(ifmap)

with open('LeNet5_ws_8x8_mem/conv1_ifmap_tile0.mem','w') as input_file:
    for i2d in range(1024):
        text_store=''
        for inchannel in reversed(range(8)):
            text_store+=np.binary_repr(ifmap_in_mem[i2d,inchannel],8)
        text_store+='\n'
        input_file.write(text_store)
                

for tileidx in range(2):
    with open('LeNet5_ws_8x8_mem/conv1_wght_tile%d.mem'%tileidx,'w') as input_file:
        text_store=''
        for inchannel in reversed(range(8)):
            text_store+=np.binary_repr(bias_in_PE[tileidx,inchannel],8)
        text_store+='\n'
        input_file.write(text_store)
        
        for k2d in range(5):
            for PEy in reversed(range(8)):
                text_store=''
                for PEx in reversed(range(8)):
                    text_store+=np.binary_repr(kernel_in_PE[tileidx,k2d,PEy,PEx],8)
                text_store+='\n'
                input_file.write(text_store)


# entire layer hex wght
with open('LeNet5_ws_8x8_mem/conv1_wght.mem','w') as input_file:
    for tileidx in range(2):
        text_store=''
        text_store+=bytes(bias_in_PE[tileidx,::-1]).hex()
        text_store+='\n'
        input_file.write(text_store)
        
        for k2d in range(5):
            for PEy in reversed(range(8)):
                text_store=''
                text_store+=bytes(kernel_in_PE[tileidx,k2d,PEy,::-1]).hex()
                text_store+='\n'
                input_file.write(text_store)
                

#%% LeNet5 weight stationary 8x8 Vivado Project ofmap validate memwrite L1

sim_set='system_2_axi_buses'

for i in range(2):
    with open('LeNet5_ws_8x8_mem/'+sim_set+'/conv1_ofmap_tile%d.mem'%i,'r') as result_file:
        RTL_ofmap_out=result_file.readlines()
    
    for p,line in enumerate(RTL_ofmap_out):
        RTL_ofmap_out[p]=np.array(list(line[:-1])).astype(np.bool)
    
    RTL_ofmap_out=np.array(RTL_ofmap_out)
    
    RTL_ofmap_out=np.split(RTL_ofmap_out,8,axis=-1)
    RTL_ofmap_out=np.stack(RTL_ofmap_out,axis=1)
    RTL_ofmap_out=np.packbits(RTL_ofmap_out, axis=-1)
    RTL_ofmap_out=np.squeeze(RTL_ofmap_out)
    
    RTL_ofmap_out=RTL_ofmap_out[:,::-1]
        
        
    ofmap_out_PE_slice=ofmap_out_PE[i]
    
    differ=np.subtract(RTL_ofmap_out,ofmap_out_PE_slice)
    print(np.sum(np.abs(differ)))


#%% LeNet5 weight stationary 8x8 Vivado Project data prep Pool1

import numpy as np
import h5py

lenet_intermediate=np.load("lenet_intermediate_hybrid_ovf.npy",allow_pickle=True)
lenet_intermediate=list(lenet_intermediate)
ifmap=lenet_intermediate[1]
ofmap=lenet_intermediate[2]

ifmap_in_PE=np.transpose(ifmap,[1,0,2])
ifmap_in_PE=np.reshape(ifmap_in_PE, [784,16])
ifmap_in_PE=np.stack(np.split(ifmap_in_PE, 16/8, axis=-1))
ifmap_in_PE=np.multiply(ifmap_in_PE,2**3)
ifmap_in_PE=ifmap_in_PE.astype(np.int8)        


ofmap_out_PE=np.transpose(ofmap,[1,0,2])
ofmap_out_PE=np.reshape(ofmap_out_PE, [196,16])
ofmap_out_PE=np.stack(np.split(ofmap_out_PE, 16/8, axis=-1))
ofmap_out_PE=np.multiply(ofmap_out_PE,2**3)
ofmap_out_PE=ofmap_out_PE.astype(np.int8)        

#%% LeNet5 weight stationary 8x8 Vivado Project textfigure gen memread Pool1

for tileidx in range(2):
    with open('LeNet5_ws_8x8_mem/pool1_ifmap_tile%d.mem'%tileidx,'w') as input_file:
        for i2d in range(784):
            text_store=''
            for inchannel in reversed(range(8)):
                #print('ifmap coor (%d,%d,%d)'%(Iridx,Icidx,inchannel))
                text_store+=np.binary_repr(ifmap_in_PE[tileidx,i2d,inchannel],8)
            text_store+='\n'
            input_file.write(text_store)
                

#%% LeNet5 weight stationary 8x8 Vivado Project ofmap validate memwrite Pool1

sim_set='pool_test'

for i in range(2):
    with open('LeNet5_ws_8x8_mem/'+sim_set+'/pool1_ofmap_tile%d.mem'%i,'r') as result_file:
        RTL_ofmap_out=result_file.readlines()
    
    for p,line in enumerate(RTL_ofmap_out):
        RTL_ofmap_out[p]=np.array(list(line[:-1])).astype(np.bool)
    
    RTL_ofmap_out=np.array(RTL_ofmap_out)
    
    RTL_ofmap_out=np.split(RTL_ofmap_out,8,axis=-1)
    RTL_ofmap_out=np.stack(RTL_ofmap_out,axis=1)
    RTL_ofmap_out=np.packbits(RTL_ofmap_out, axis=-1)
    RTL_ofmap_out=np.squeeze(RTL_ofmap_out)
    
    RTL_ofmap_out=RTL_ofmap_out[:,::-1]
        
        
    ofmap_out_PE_slice=ofmap_out_PE[i]
    
    differ=np.subtract(RTL_ofmap_out,ofmap_out_PE_slice)
    print(np.sum(np.abs(differ)))


#%% LeNet5 weight stationary 8x8 Vivado Project data prep L2

import numpy as np
import h5py

lenet_intermediate=np.load("lenet_intermediate_hybrid_ovf.npy",allow_pickle=True)
lenet_intermediate=list(lenet_intermediate)
ifmap=lenet_intermediate[2]
ofmap=lenet_intermediate[3]

with h5py.File("mnist_lenet5_weight.h5",'r') as weight_f:
    kernel=weight_f['conv2d_2']['conv2d_2/kernel:0'][()]
    bias=weight_f['conv2d_2']['conv2d_2/bias:0'][()]

kernel_in=np.transpose(kernel,(3,1,0,2))
kernel_in=np.reshape(kernel_in,[36,5*5*16])
kernel_in=np.transpose(kernel_in)

ofmap_out=np.transpose(ofmap,(2,1,0))
ofmap_out=np.reshape(ofmap_out,[36,196])
ofmap_out=np.transpose(ofmap_out)

# 8x8 PE WS
ofmap_out_PE=np.pad(ofmap_out,((0, 0), (0, 12)),'constant',constant_values=0)
ofmap_out_PE=np.stack(np.split(ofmap_out_PE,48/16,axis=-1))
ofmap_out_PE=np.stack(np.split(ofmap_out_PE,16/8,axis=-1),axis=1)
ofmap_out_PE=np.multiply(ofmap_out_PE,2**3)
ofmap_out_PE=ofmap_out_PE.astype(np.int8)
# [tile,slice,clk,PE_x]


kernel_in_PE=np.pad(kernel_in,((0, 0), (0, 12)),'constant',constant_values=0)
kernel_in_PE=np.stack(np.split(kernel_in_PE,48/16,axis=-1))
kernel_in_PE=np.stack(np.split(kernel_in_PE,16/8,axis=-1),axis=1)
kernel_in_PE=np.stack(np.split(kernel_in_PE,400/16,axis=-2),axis=2)
kernel_in_PE=np.stack(np.split(kernel_in_PE,16/8,axis=-2),axis=3)
kernel_in_PE=np.multiply(kernel_in_PE,2**3)
kernel_in_PE=np.round(kernel_in_PE)
kernel_in_PE=kernel_in_PE.astype(np.int8)
# [tile, slice_outchannel, slice_kernelRC, slice_inchannel, PE_y, PE_x]
bias_in_PE=np.pad(bias,(0,12),'constant',constant_values=0)
bias_in_PE=np.stack(np.split(bias_in_PE,48/16))
bias_in_PE=np.stack(np.split(bias_in_PE,16/8,axis=-1),axis=1)
bias_in_PE=np.multiply(bias_in_PE,2**3)
bias_in_PE=np.round(bias_in_PE)
bias_in_PE=bias_in_PE.astype(np.int8)
# [tile,slice,PE_x]


#%% LeNet5 weight stationary 8x8 Vivado Project textfigure gen memread L2

pad=False

if pad:
    ifmap_in_mem=np.pad(ifmap,((2, 2), (2, 2), (0,0)),'constant',constant_values=0)
    ifmap_in_mem=np.multiply(ifmap_in_mem,2**3)
    ifmap_in_mem=ifmap_in_mem.astype(np.int8)
    
    with open('LeNet5_ws_8x8_mem/conv2_ifmap_tile0.mem','w') as input_file:
        for ichsplit in [range(0,8),range(8,16)]:
            for Icidx in range(18):
                for Iridx in range(18):
                    text_store=''
                    for inchannel in reversed(ichsplit):
                        #print('ifmap coor (%d,%d,%d)'%(Iridx,Icidx,inchannel))
                        text_store+=np.binary_repr(ifmap_in_mem[Iridx,Icidx,inchannel],8)
                    text_store+='\n'
                    input_file.write(text_store)
else:
    ifmap_in_mem=np.multiply(ifmap,2**3)
    ifmap_in_mem=ifmap_in_mem.astype(np.int8)
    
    with open('LeNet5_ws_8x8_mem/conv2_ifmap_tile0.mem','w') as input_file:
        for ichsplit in [range(0,8),range(8,16)]:
            for Icidx in range(14):
                for Iridx in range(14):
                    text_store=''
                    for inchannel in reversed(ichsplit):
                        #print('ifmap coor (%d,%d,%d)'%(Iridx,Icidx,inchannel))
                        text_store+=np.binary_repr(ifmap_in_mem[Iridx,Icidx,inchannel],8)
                    text_store+='\n'
                    input_file.write(text_store)
                
                

for tileidx in range(3):
    with open('LeNet5_ws_8x8_mem/conv2_wght_tile%d.mem'%tileidx,'w') as input_file:
        for biasidx in range(2):
            text_store=''
            for inchannel in reversed(range(8)):
                text_store+=np.binary_repr(bias_in_PE[tileidx,biasidx,inchannel],8)
            text_store+='\n'
            input_file.write(text_store)
        
        for ochsplit in range(2):
            for k2d in range(25):
                for ichsplit in range(2):
                    for PEy in reversed(range(8)):
                        text_store=''
                        for PEx in reversed(range(8)):
                            text_store+=np.binary_repr(kernel_in_PE[tileidx,ochsplit,k2d,ichsplit,PEy,PEx],8)
                        text_store+='\n'
                        input_file.write(text_store)

# entire layer hex wght
with open('LeNet5_ws_8x8_mem/conv2_wght.mem','w') as input_file:
    for tileidx in range(3):
        for biasidx in range(2):
            text_store=''
            text_store+=bytes(bias_in_PE[tileidx,biasidx,::-1]).hex()
            text_store+='\n'
            input_file.write(text_store)
        
        for ochsplit in range(2):
            for k2d in range(25):
                for ichsplit in range(2):
                    for PEy in reversed(range(8)):
                        text_store=''
                        text_store+=bytes(kernel_in_PE[tileidx,ochsplit,k2d,ichsplit,PEy,::-1]).hex()
                        text_store+='\n'
                        input_file.write(text_store)
                

#%% LeNet5 weight stationary 8x8 Vivado Project ofmap validate memwrite L2

sim_set='system_2_axi_buses'

for i in range(3):
    with open('LeNet5_ws_8x8_mem/'+sim_set+'/conv2_ofmap_tile%d.mem'%i,'r') as result_file:
        RTL_ofmap_out=result_file.readlines()
    
    for p,line in enumerate(RTL_ofmap_out):
        RTL_ofmap_out[p]=np.array(list(line[:-1])).astype(np.bool)
    
    RTL_ofmap_out=np.array(RTL_ofmap_out)
    
    RTL_ofmap_out=np.split(RTL_ofmap_out,8,axis=-1)
    RTL_ofmap_out=np.stack(RTL_ofmap_out,axis=1)
    RTL_ofmap_out=np.packbits(RTL_ofmap_out, axis=-1)
    RTL_ofmap_out=np.squeeze(RTL_ofmap_out)
    
    RTL_ofmap_out=RTL_ofmap_out[:,::-1]
    RTL_ofmap_out=np.split(RTL_ofmap_out,2)
    RTL_ofmap_out=np.concatenate(RTL_ofmap_out,axis=1)
        
    # RTL_ofmap_out=np.reshape(RTL_ofmap_out, [14,14,16])
    # RTL_ofmap_out=np.transpose(RTL_ofmap_out,[1,0,2])
        
    ofmap_out_PE_slice=ofmap_out_PE[i]
    ofmap_out_PE_slice=np.concatenate(ofmap_out_PE_slice,axis=1)
    # ofmap_out_PE_slice=np.reshape(ofmap_out_PE_slice, [14,14,16])
    # ofmap_out_PE_slice=np.transpose(ofmap_out_PE_slice,[1,0,2])
    
    differ=np.subtract(RTL_ofmap_out,ofmap_out_PE_slice)
    print(np.sum(np.abs(differ)))



#%% LeNet5 weight stationary 8x8 Vivado Project data prep Pool2

import numpy as np
import h5py

lenet_intermediate=np.load("lenet_intermediate_hybrid_ovf.npy",allow_pickle=True)
lenet_intermediate=list(lenet_intermediate)
ifmap=lenet_intermediate[3]
ofmap=lenet_intermediate[4]

ifmap_in=np.transpose(ifmap,(2,1,0))
ifmap_in=np.reshape(ifmap_in,[36,196])
ifmap_in=np.transpose(ifmap_in)

# 8x8 PE WS
ifmap_in_PE=np.pad(ifmap_in,((0, 0), (0, 12)),'constant',constant_values=0)
ifmap_in_PE=np.stack(np.split(ifmap_in_PE,48/16,axis=-1))
ifmap_in_PE=np.stack(np.split(ifmap_in_PE,16/8,axis=-1),axis=1)
ifmap_in_PE=np.multiply(ifmap_in_PE,2**3)
ifmap_in_PE=ifmap_in_PE.astype(np.int8)
# [tile,slice,clk,PE_x]


ofmap_out=np.transpose(ofmap,(2,1,0))
ofmap_out=np.reshape(ofmap_out,[36,49])
ofmap_out=np.transpose(ofmap_out)

# 8x8 PE WS
ofmap_out_PE=np.pad(ofmap_out,((0, 0), (0, 12)),'constant',constant_values=0)
ofmap_out_PE=np.stack(np.split(ofmap_out_PE,48/16,axis=-1))
ofmap_out_PE=np.stack(np.split(ofmap_out_PE,16/8,axis=-1),axis=1)
ofmap_out_PE=np.multiply(ofmap_out_PE,2**3)
ofmap_out_PE=ofmap_out_PE.astype(np.int8)
# [tile,slice,clk,PE_x]

#%% LeNet5 weight stationary 8x8 Vivado Project textfigure gen memread Pool2

for tileidx in range(3):
    with open('LeNet5_ws_8x8_mem/pool2_ifmap_tile%d.mem'%tileidx,'w') as input_file:
        for ichsplit in range(2):
            for i2d in range(196):
                text_store=''
                for inchannel in reversed(range(8)):
                    #print('ifmap coor (%d,%d,%d)'%(Iridx,Icidx,inchannel))
                    text_store+=np.binary_repr(ifmap_in_PE[tileidx,ichsplit,i2d,inchannel],8)
                text_store+='\n'
                input_file.write(text_store)                            
                

#%% LeNet5 weight stationary 8x8 Vivado Project ofmap validate memwrite L2

sim_set='pool_test'

for i in range(3):
    with open('LeNet5_ws_8x8_mem/'+sim_set+'/pool2_ofmap_tile%d.mem'%i,'r') as result_file:
        RTL_ofmap_out=result_file.readlines()
    
    for p,line in enumerate(RTL_ofmap_out):
        RTL_ofmap_out[p]=np.array(list(line[:-1])).astype(np.bool)
    
    RTL_ofmap_out=np.array(RTL_ofmap_out)
    
    RTL_ofmap_out=np.split(RTL_ofmap_out,8,axis=-1)
    RTL_ofmap_out=np.stack(RTL_ofmap_out,axis=1)
    RTL_ofmap_out=np.packbits(RTL_ofmap_out, axis=-1)
    RTL_ofmap_out=np.squeeze(RTL_ofmap_out)
    
    RTL_ofmap_out=RTL_ofmap_out[:,::-1]
    RTL_ofmap_out=np.split(RTL_ofmap_out,2)
    RTL_ofmap_out=np.concatenate(RTL_ofmap_out,axis=1)
        
    # RTL_ofmap_out=np.reshape(RTL_ofmap_out, [14,14,16])
    # RTL_ofmap_out=np.transpose(RTL_ofmap_out,[1,0,2])
        
    ofmap_out_PE_slice=ofmap_out_PE[i]
    ofmap_out_PE_slice=np.concatenate(ofmap_out_PE_slice,axis=1)
    # ofmap_out_PE_slice=np.reshape(ofmap_out_PE_slice, [14,14,16])
    # ofmap_out_PE_slice=np.transpose(ofmap_out_PE_slice,[1,0,2])
    
    differ=np.subtract(RTL_ofmap_out,ofmap_out_PE_slice)
    print(np.sum(np.abs(differ)))

#%% LeNet5 weight stationary 8x8 Vivado Project data prep FC1

import numpy as np
import h5py

lenet_intermediate=np.load("lenet_intermediate_hybrid_ovf.npy",allow_pickle=True)
lenet_intermediate=list(lenet_intermediate)
ifmap=lenet_intermediate[5]
ofmap=lenet_intermediate[6]

with h5py.File("mnist_lenet5_weight.h5",'r') as weight_f:
    kernel=weight_f['dense_1']['dense_1/kernel:0'][()]
    bias=weight_f['dense_1']['dense_1/bias:0'][()]

kernel_in=np.reshape(kernel,(7,7,36,128))
kernel_in=np.transpose(kernel_in,[1,0,2,3])
kernel_in=np.reshape(kernel_in,[7*7*36,128])

kernel_in_PE=np.pad(kernel_in,((0, 12), (0, 0)),'constant',constant_values=0)
kernel_in_PE=np.stack(np.split(kernel_in_PE,128/8,axis=-1))
kernel_in_PE=np.stack(np.split(kernel_in_PE,2,axis=1),axis=1)
kernel_in_PE=np.stack(np.split(kernel_in_PE,888/8,axis=2),axis=2)
kernel_in_PE=np.multiply(kernel_in_PE,2**3)
kernel_in_PE=np.round(kernel_in_PE)
kernel_in_PE=kernel_in_PE.astype(np.int8)
# [slice_outchannel, slice_inchannel, slice_kernel, PE_y, PE_x]
bias_in_PE=np.stack(np.split(bias,128/8))
bias_in_PE=np.multiply(bias_in_PE,2**3)
bias_in_PE=np.round(bias_in_PE)
bias_in_PE=bias_in_PE.astype(np.int8)
# [tile,PE_x]

#%% LeNet5 weight stationary 8x8 Vivado Project textfigure gen memread FC1

with open('LeNet5_ws_8x8_mem/fc1_wght.mem','w') as input_file:    
    for ochsplit in range(16):
        text_store=''
        text_store+=bytes(bias_in_PE[ochsplit,::-1]).hex()
        text_store+='\n'
        input_file.write(text_store)
        
        for ichsplit in range(2):
            for kslc in range(111):
                for PEy in reversed(range(8)):
                    text_store=''
                    text_store+=bytes(kernel_in_PE[ochsplit,ichsplit,kslc,PEy,::-1]).hex()
                    text_store+='\n'
                    input_file.write(text_store)
            
    

#%% LeNet5 weight stationary 8x8 Vivado Project data prep FC2

import numpy as np
import h5py

lenet_intermediate=np.load("lenet_intermediate_hybrid_ovf.npy",allow_pickle=True)
lenet_intermediate=list(lenet_intermediate)
ifmap=lenet_intermediate[6]
ofmap=lenet_intermediate[7]

with h5py.File("mnist_lenet5_weight.h5",'r') as weight_f:
    kernel=weight_f['dense_2']['dense_2/kernel:0'][()]
    bias=weight_f['dense_2']['dense_2/bias:0'][()]


kernel_in_PE=np.pad(kernel,((0, 0), (0, 6)),'constant',constant_values=0)
kernel_in_PE=np.stack(np.split(kernel_in_PE,16/8,axis=-1))
kernel_in_PE=np.stack(np.split(kernel_in_PE,128/8,axis=1),axis=1)
kernel_in_PE=np.multiply(kernel_in_PE,2**3)
kernel_in_PE=np.round(kernel_in_PE)
kernel_in_PE=kernel_in_PE.astype(np.int8)
# [slice_outchannel, slice_inchannel, slice_kernel, PE_y, PE_x]
bias_in_PE=np.pad(bias,(0,6),'constant',constant_values=0)
bias_in_PE=np.stack(np.split(bias_in_PE,16/8))
bias_in_PE=np.multiply(bias_in_PE,2**3)
bias_in_PE=np.round(bias_in_PE)
bias_in_PE=bias_in_PE.astype(np.int8)
# [tile,PE_x]


#%% LeNet5 weight stationary 8x8 Vivado Project textfigure gen memread FC2

with open('LeNet5_ws_8x8_mem/fc2_wght.mem','w') as input_file:    
    for ochsplit in range(2):
        text_store=''
        text_store+=bytes(bias_in_PE[ochsplit,::-1]).hex()
        text_store+='\n'
        input_file.write(text_store)
        
        for kslc in range(16):
            for PEy in reversed(range(8)):
                text_store=''
                text_store+=bytes(kernel_in_PE[ochsplit,kslc,PEy,::-1]).hex()
                text_store+='\n'
                input_file.write(text_store)
                
    
#%% LeNet5 weight stationary 8x8 Vivado Project data prep Conv1->Pool1->Conv2->Pool2->FC1

import numpy as np
import h5py

lenet_intermediate=np.load("lenet_intermediate_hybrid_ovf.npy",allow_pickle=True)
lenet_intermediate=list(lenet_intermediate)
ifmap=lenet_intermediate[0]
ofmap=lenet_intermediate[4]

def preprocess_input_img_mem(img):
    # img shape (28,28,1)
    img_processed=np.pad(img,((2, 2), (2, 2), (0,0)),'constant',constant_values=0)
    img_processed=np.multiply(img_processed,2**3)
    img_processed=img_processed.astype(np.int8)
    
    img_processed=np.transpose(img_processed,[1,0,2])
    img_processed=np.reshape(img_processed, [32*32,1])
    img_processed=np.tile(img_processed,[1,5])
    
    roller=np.array([  0,   1,   2,   3,   4])
    
    for i in range(img_processed.shape[1]):
        img_processed[:,i]=np.roll(img_processed[:,i],-roller[i])
        
    img_processed=np.pad(img_processed,((0, 0), (0, 3)),'constant',constant_values=0)
    
    return img_processed

ifmap_in_mem=preprocess_input_img_mem(ifmap)

ofmap_out=np.transpose(ofmap,(2,1,0))
ofmap_out=np.reshape(ofmap_out,[36,49])
ofmap_out=np.transpose(ofmap_out)

# 8x8 PE WS
ofmap_out_PE=np.pad(ofmap_out,((0, 0), (0, 12)),'constant',constant_values=0)
ofmap_out_PE=np.stack(np.split(ofmap_out_PE,48/16,axis=-1))
ofmap_out_PE=np.stack(np.split(ofmap_out_PE,16/8,axis=-1),axis=1)
ofmap_out_PE=np.multiply(ofmap_out_PE,2**3)
ofmap_out_PE=ofmap_out_PE.astype(np.int8)
# [tile,slice,clk,PE_x]

#%% LeNet5 weight stationary 8x8 Vivado Project textfigure gen memread Conv1->Pool1->Conv2->Pool2->FC1

with open('LeNet5_ws_8x8_mem/conv1_ifmap_tile0.mem','w') as input_file:
    for i2d in range(1024):
        text_store=''
        for inchannel in reversed(range(8)):
            #print('ifmap coor (%d,%d,%d)'%(Iridx,Icidx,inchannel))
            text_store+=np.binary_repr(ifmap_in_mem[i2d,inchannel],8)
        text_store+='\n'
        input_file.write(text_store)                     
                

#%% LeNet5 weight stationary 8x8 Vivado Project ofmap validate memwrite Conv1->Pool1->Conv2->Pool2->FC1

sim_set='system_2_axi_buses_v1_1'

with open('LeNet5_ws_8x8_mem/'+sim_set+'/FC1_ifmap_tile0.mem','r') as result_file:
    RTL_ofmap_out=result_file.readlines()

for p,line in enumerate(RTL_ofmap_out):
    RTL_ofmap_out[p]=np.array(list(line[:-1])).astype(np.bool)

RTL_ofmap_out=np.array(RTL_ofmap_out)

RTL_ofmap_out=np.split(RTL_ofmap_out,8,axis=-1)
RTL_ofmap_out=np.stack(RTL_ofmap_out,axis=1)
RTL_ofmap_out=np.packbits(RTL_ofmap_out, axis=-1)
RTL_ofmap_out=np.squeeze(RTL_ofmap_out)

RTL_ofmap_out=RTL_ofmap_out[:,::-1]
RTL_ofmap_out=np.split(RTL_ofmap_out,3)
RTL_ofmap_out=np.stack(RTL_ofmap_out)
RTL_ofmap_out=np.split(RTL_ofmap_out,2,axis=1)
RTL_ofmap_out=np.stack(RTL_ofmap_out,axis=1)
    
# RTL_ofmap_out=np.reshape(RTL_ofmap_out, [14,14,16])
# RTL_ofmap_out=np.transpose(RTL_ofmap_out,[1,0,2])
    
# ofmap_out_PE_slice=np.concatenate(ofmap_out_PE,axis=1)
# ofmap_out_PE_slice=np.concatenate(ofmap_out_PE_slice,axis=1)
# ofmap_out_PE_slice=np.reshape(ofmap_out_PE_slice, [14,14,16])
# ofmap_out_PE_slice=np.transpose(ofmap_out_PE_slice,[1,0,2])

differ=np.subtract(RTL_ofmap_out,ofmap_out_PE)
print(np.sum(np.abs(differ)))

#%% LeNet5 weight stationary 8x8 Vivado Project data prep Conv1->Pool1->Conv2->Pool2->FC1->FC2

import numpy as np
import h5py

lenet_intermediate=np.load("lenet_intermediate_hybrid_ovf.npy",allow_pickle=True)
lenet_intermediate=list(lenet_intermediate)
ifmap=lenet_intermediate[0]
ofmap=lenet_intermediate[7]

with h5py.File("mnist_lenet5_weight.h5",'r') as weight_f:
    kernel=weight_f['dense_1']['dense_1/kernel:0'][()]
    bias=weight_f['dense_1']['dense_1/bias:0'][()]

def preprocess_input_img_mem(img):
    # img shape (28,28,1)
    img_processed=np.pad(img,((2, 2), (2, 2), (0,0)),'constant',constant_values=0)
    img_processed=np.multiply(img_processed,2**3)
    img_processed=img_processed.astype(np.int8)
    
    img_processed=np.transpose(img_processed,[1,0,2])
    img_processed=np.reshape(img_processed, [32*32,1])
    img_processed=np.tile(img_processed,[1,5])
    
    roller=np.array([  0,   1,   2,   3,   4])
    
    for i in range(img_processed.shape[1]):
        img_processed[:,i]=np.roll(img_processed[:,i],-roller[i])
        
    img_processed=np.pad(img_processed,((0, 0), (0, 3)),'constant',constant_values=0)
    
    return img_processed

ifmap_in_mem=preprocess_input_img_mem(ifmap)




