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

kernel_in=np.reshape(kernel,(7,7,36,128))

kernel_in_PE=np.pad(kernel_in,((0, 0), (0, 0), (0, 4), (0, 0)),'constant',constant_values=0)
kernel_in_PE=np.transpose(kernel_in_PE,[1,0,2,3])
kernel_in_PE=np.stack(np.split(kernel_in_PE,40/8,axis=2))
kernel_in_PE=np.reshape(kernel_in_PE, [5*7*7,8,128])

kernel_in_PE=np.stack(np.split(kernel_in_PE,128/8,axis=-1))
kernel_in_PE=np.multiply(kernel_in_PE,2**3)
kernel_in_PE=np.round(kernel_in_PE)
kernel_in_PE=kernel_in_PE.astype(np.int8)
# [slice_outchannel, slice_inchannel, PE_y, PE_x]
bias_in_PE=np.stack(np.split(bias,128/8))
bias_in_PE=np.multiply(bias_in_PE,2**3)
bias_in_PE=np.round(bias_in_PE)
bias_in_PE=bias_in_PE.astype(np.int8)
# [tile,PE_x]



with open('SDK_lib/fc1_wght.hpp','w') as lib_file:
    lib_file.write('volatile unsigned long long fc1_wght[31376] = {\n')
    
    for ochsplit in range(16):
        text_store='0x'
        text_store+=bytes(bias_in_PE[ochsplit,::-1]).hex()
        text_store+=' ,\n'
        lib_file.write(text_store)
        
        for ichsplit in range(245):
            for PEy in reversed(range(8)):
                text_store='0x'
                text_store+=bytes(kernel_in_PE[ochsplit,ichsplit,PEy,::-1]).hex()
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
    
    for biasidx in range(2):
        text_store='0x'
        text_store+=bytes(bias_in_PE[biasidx,::-1]).hex()
        text_store+=' ,\n'
        lib_file.write(text_store)
    
    for ochsplit in range(2):
        for kslc in range(16):
            for PEy in reversed(range(8)):
                text_store='0x'
                text_store+=bytes(kernel_in_PE[ochsplit,kslc,PEy,::-1]).hex()
                text_store+=' ,\n'
                lib_file.write(text_store)
                
    lib_file.write('};')

#%% number4 ref pic gen

import numpy as np

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

ref_pic=np.load("ref_number4_pic.npy")

ref_pic=preprocess_input_img_mem(ref_pic)

with open('SDK_lib/ref_pic.hpp','w') as lib_file:
    lib_file.write('volatile unsigned long long ref_pic[1024] = {\n')
    
    for row in range(1024):
        text_store='0x'
        text_store+=bytes(ref_pic[row,::-1]).hex()
        text_store+=' ,\n'
        lib_file.write(text_store)
                
    lib_file.write('};')
        
#%% ofmap data prep conv1 

import numpy as np

lenet_intermediate=np.load("lenet_intermediate_hybrid_ovf.npy",allow_pickle=True)
lenet_intermediate=list(lenet_intermediate)
ofmap=lenet_intermediate[1]

ofmap_out_PE=np.transpose(ofmap,[1,0,2])
ofmap_out_PE=np.reshape(ofmap_out_PE, [784,16])
ofmap_out_PE=np.stack(np.split(ofmap_out_PE, 16/8, axis=-1))
ofmap_out_PE=np.multiply(ofmap_out_PE,2**3)
ofmap_out_PE=ofmap_out_PE.astype(np.int8)   


#%% validate SDK export binary file conv1

import numpy as np

filename='conv1_ofmap.bin'
ofmap_bytes=list()
with open('SDK_bin/'+filename,'rb') as bin_output_file:
    byte=bin_output_file.read(1)
    while byte:
        ofmap_bytes.append(byte)
        byte=bin_output_file.read(1)
    
ofmap_bytes=np.array(ofmap_bytes)
ofmap_sdk=np.frombuffer(ofmap_bytes,np.int8)
ofmap_sdk=np.reshape(ofmap_sdk, [2,784,8])

differ=np.subtract(ofmap_sdk,ofmap_out_PE)
print(np.sum(np.abs(differ)))

#%% ofmap data prep conv2

import numpy as np

lenet_intermediate=np.load("lenet_intermediate_hybrid_ovf.npy",allow_pickle=True)
lenet_intermediate=list(lenet_intermediate)
ofmap=lenet_intermediate[4]

ofmap_out=np.transpose(ofmap,(2,1,0))
ofmap_out=np.reshape(ofmap_out,[36,49])
ofmap_out=np.transpose(ofmap_out)

# 8x8 PE WS
ofmap_out_PE=np.pad(ofmap_out,((0, 0), (0, 12)),'constant',constant_values=0)
ofmap_out_PE=np.stack(np.split(ofmap_out_PE,48/16,axis=-1))
ofmap_out_PE=np.stack(np.split(ofmap_out_PE,16/8,axis=-1),axis=1)
ofmap_out_PE=np.multiply(ofmap_out_PE,2**3)
ofmap_out_PE=ofmap_out_PE.astype(np.int32)
 


#%% validate SDK export binary file conv2

import numpy as np

filename='fc1_ifmap.bin'
ofmap_bytes=list()
with open('SDK_bin/'+filename,'rb') as bin_output_file:
    byte=bin_output_file.read(1)
    while byte:
        ofmap_bytes.append(byte)
        byte=bin_output_file.read(1)
    
ofmap_bytes=np.array(ofmap_bytes)
ofmap_sdk=np.frombuffer(ofmap_bytes,np.int8)
ofmap_sdk=np.reshape(ofmap_sdk, [3,2,49,8])

differ=np.subtract(ofmap_sdk,ofmap_out_PE)
print(np.sum(np.abs(differ)))

#%% ofmap data prep fc1

import numpy as np
import h5py

lenet_intermediate=np.load("lenet_intermediate_hybrid_ovf.npy",allow_pickle=True)
lenet_intermediate=list(lenet_intermediate)
ofmap=lenet_intermediate[6]

ofmap_out_PE=np.multiply(ofmap,2**3)
ofmap_out_PE=ofmap_out_PE.astype(np.int8)

#%% validate SDK export binary file fc1

import numpy as np

filename='fc1_ofmap.bin'
ofmap_bytes=list()
with open('SDK_bin/'+filename,'rb') as bin_output_file:
    byte=bin_output_file.read(1)
    while byte:
        ofmap_bytes.append(byte)
        byte=bin_output_file.read(1)
    
ofmap_bytes=np.array(ofmap_bytes)
ofmap_sdk=np.frombuffer(ofmap_bytes,np.int8)

differ=np.subtract(ofmap_sdk,ofmap_out_PE)
print(np.sum(np.abs(differ)))

#%% ofmap data prep fc2 

import numpy as np
import h5py

lenet_intermediate=np.load("lenet_intermediate_hybrid_ovf.npy",allow_pickle=True)
lenet_intermediate=list(lenet_intermediate)
predin=lenet_intermediate[6]

with h5py.File("mnist_lenet5_weight.h5",'r') as weight_f:
    kernel=weight_f['dense_2']['dense_2/kernel:0'][()]
    bias=weight_f['dense_2']['dense_2/bias:0'][()]


kernel_in=np.multiply(kernel,2**3)
kernel_in=np.round(kernel_in)
kernel_in=kernel_in.astype(np.int8)

pred_in_PE=np.multiply(predin,2**3)
pred_in_PE=pred_in_PE.astype(np.int8)

pred_out=np.dot(pred_in_PE.astype(np.int32),kernel_in.astype(np.int32))
pred_out=np.floor_divide(pred_out, 2**3)
pred_out=np.clip(pred_out, -128, 127)
pred_out=pred_out.astype(np.int8)


#%% validate SDK export binary file fc2

import numpy as np

filename='pred.bin'
ofmap_bytes=list()
with open('SDK_bin/'+filename,'rb') as bin_output_file:
    byte=bin_output_file.read(1)
    while byte:
        ofmap_bytes.append(byte)
        byte=bin_output_file.read(1)
    
ofmap_bytes=np.array(ofmap_bytes)[:10]
ofmap_sdk=np.frombuffer(ofmap_bytes,np.int8)

differ=np.subtract(ofmap_sdk,pred_out)
print(np.sum(np.abs(differ)))


#%% Mnist dataset SDK bin files data prep

import numpy as np
from tensorflow.keras.datasets import mnist

def preprocess_input_img_sdk_dataset(img):
    # img shape (28,28)
    img_processed=np.pad(img,((2, 2), (2, 2)),'constant',constant_values=0)
    img_processed=np.multiply(img_processed,2**3)
    img_processed=np.floor(img_processed)
    img_processed=img_processed.astype(np.int8)
    
    img_processed=np.transpose(img_processed,[1,0])
    img_processed=np.reshape(img_processed, [32*32,1])
    img_processed=np.tile(img_processed,[1,5])
    
    roller=np.array([  0,   1,   2,   3,   4])
    
    for i in range(img_processed.shape[1]):
        img_processed[:,i]=np.roll(img_processed[:,i],-roller[i])
        
    img_processed=np.pad(img_processed,((0, 0), (0, 3)),'constant',constant_values=0)
    
    return img_processed

(_, _), (x_test, y_test) = mnist.load_data()
x_test=x_test.astype('float32')
x_test=np.divide(x_test,255)


#%% Mnist dataset generate input pic bin files

import os

# for picidx in range(10000):
    
#     test_pic=x_test[picidx]
#     test_pic=preprocess_input_img_sdk_dataset(test_pic)
#     bt_test_pic=bytearray(test_pic)
    
#     pic_save_dir='../../dataset/mnist_hierachy_hex/%04x.bin'%picidx
   
#     with open(pic_save_dir,'wb') as bin_img_file:
#         bin_img_file.write(bt_test_pic)


# for picidx in np.ndindex(10,1000):
    
#     test_pic=x_test[np.ravel_multi_index(picidx,[10,1000])]
#     test_pic=preprocess_input_img_sdk_dataset(test_pic)
#     bt_test_pic=bytearray(test_pic)
    
#     pic_save_dir='../../dataset/mnist_hierachy3/%d'%picidx[0]
#     if not os.path.isdir(pic_save_dir):
#         os.mkdir(pic_save_dir)
   
#     with open(pic_save_dir+'/img%03d.bin'%picidx[1],'wb') as bin_img_file:
#         bin_img_file.write(bt_test_pic)

for picidx in np.ndindex(500,20):
    
    test_pic=x_test[np.ravel_multi_index(picidx,[500,20])]
    test_pic=preprocess_input_img_sdk_dataset(test_pic)
    bt_test_pic=bytearray(test_pic)
    
    pic_save_dir='../../dataset/mnist_fmultipic2/%03d.bin'%picidx[0]
   
    if picidx[1]==0:
        with open(pic_save_dir,'wb') as bin_img_file:
            bin_img_file.write(bt_test_pic)
    else:        
        with open(pic_save_dir,'ab') as bin_img_file:
            bin_img_file.write(bt_test_pic)

#%% Mnist dataset validate output pred bin files

pred_sdk=list()
with open('SDK_bin/dataset_pred.bin','rb') as bin_pred_file:
    byte=bin_pred_file.read(1)
    while byte:
        pred_sdk.append(byte)
        byte=bin_pred_file.read(1)

pred_sdk=np.array(pred_sdk)
pred_sdk=np.frombuffer(pred_sdk,np.int8)

pred_sdk=np.reshape(pred_sdk, [10000,16])
pred_sdk=pred_sdk[:,:10]

pred_sdk=np.argmax(pred_sdk,axis=1)

accuracy=np.mean(np.equal(pred_sdk,y_test))

print('FPGA inference accuracy %.4f'%accuracy)

