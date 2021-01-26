# -*- coding: utf-8 -*-
"""
Created on Mon Jan 25 14:48:56 2021

@author: Yung-Yu Tsai

SDK .hpp data gen

"""

#%% conv1 weight gen

import numpy as np
import h5py


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



with open('SDK_lib/conv1_wght.hpp','w') as lib_file:
    lib_file.write('volatile unsigned long long conv1_wght[82] = {\n')
    
    for tileidx in range(2):    
        text_store='0x'
        text_store+=bytes(bias_in_PE[tileidx,::-1]).hex()
        text_store+=' ,\n'
        lib_file.write(text_store)
        
        for k2d in range(5):
            for PEy in reversed(range(8)):
                text_store='0x'
                text_store+=bytes(kernel_in_PE[tileidx,k2d,PEy,::-1]).hex()
                text_store+=' ,\n'
                lib_file.write(text_store)
                
    lib_file.write('};')

#%% conv2 weight gen

import numpy as np
import h5py


with h5py.File("mnist_lenet5_weight.h5",'r') as weight_f:
    kernel=weight_f['conv2d_2']['conv2d_2/kernel:0'][()]
    bias=weight_f['conv2d_2']['conv2d_2/bias:0'][()]

kernel_in=np.transpose(kernel,(3,1,0,2))
kernel_in=np.reshape(kernel_in,[36,5*5*16])
kernel_in=np.transpose(kernel_in)

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



with open('SDK_lib/conv2_wght.hpp','w') as lib_file:
    lib_file.write('volatile unsigned long long conv2_wght[2406] = {\n')
    
    for tileidx in range(3):
        for biasidx in range(2):
            text_store='0x'
            text_store+=bytes(bias_in_PE[tileidx,biasidx,::-1]).hex()
            text_store+=' ,\n'
            lib_file.write(text_store)
        
        for ochsplit in range(2):
            for k2d in range(25):
                for ichsplit in range(2):
                    for PEy in reversed(range(8)):
                        text_store='0x'
                        text_store+=bytes(kernel_in_PE[tileidx,ochsplit,k2d,ichsplit,PEy,::-1]).hex()
                        text_store+=' ,\n'
                        lib_file.write(text_store)
                
    lib_file.write('};')


#%% FC1 weight gen

import numpy as np
import h5py


with h5py.File("mnist_lenet5_weight.h5",'r') as weight_f:
    kernel=weight_f['dense_1']['dense_1/kernel:0'][()]
    bias=weight_f['dense_1']['dense_1/bias:0'][()]


kernel_in_PE=np.stack(np.split(kernel,128/8,axis=-1))
kernel_in_PE=np.stack(np.split(kernel_in_PE,1764/882,axis=1),axis=1)
kernel_in_PE=np.pad(kernel_in_PE,((0, 0), (0, 0), (0, 6), (0, 0)),'constant',constant_values=0)
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



with open('SDK_lib/fc1_wght.hpp','w') as lib_file:
    lib_file.write('volatile unsigned long long fc1_wght[28432] = {\n')
    
    for ochsplit in range(16):
        text_store='0x'
        text_store+=bytes(bias_in_PE[ochsplit,::-1]).hex()
        text_store+=' ,\n'
        lib_file.write(text_store)
        
        for ichsplit in range(2):
            for kslc in range(111):
                for PEy in reversed(range(8)):
                    text_store='0x'
                    text_store+=bytes(kernel_in_PE[ochsplit,ichsplit,kslc,PEy,::-1]).hex()
                    text_store+=' ,\n'
                    lib_file.write(text_store)
                
    lib_file.write('};')

#%% FC2 weight gen

import numpy as np
import h5py


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



with open('SDK_lib/fc2_wght.hpp','w') as lib_file:
    lib_file.write('volatile unsigned long long fc2_wght[258] = {\n')
    
    for ochsplit in range(2):
        text_store='0x'
        text_store+=bytes(bias_in_PE[ochsplit,::-1]).hex()
        text_store+=' ,\n'
        lib_file.write(text_store)
        
        for kslc in range(16):
            for PEy in reversed(range(8)):
                text_store='0x'
                text_store+=bytes(kernel_in_PE[ochsplit,kslc,PEy,::-1]).hex()
                text_store+=' ,\n'
                lib_file.write(text_store)
                
    lib_file.write('};')
