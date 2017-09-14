#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Jul 14 11:40:43 2017

@author: engs1314
"""


import numpy as np
import scipy.io
#from scipy import signal
from sklearn import preprocessing
import os, sys,random

'''
##############################
  Loads the augmented dataset
##############################
'''
def load3D(feats):    
    FS = 300
    WIN = 30
    print("Loading data training set")    
    matfileval = scipy.io.loadmat('/sharedfolder/preparation/augmented/train3d_val.mat')
    matfile1 = scipy.io.loadmat('/sharedfolder/preparation/augmented/train3d_1.mat')
    matfile2 = scipy.io.loadmat('/sharedfolder/preparation/augmented/train3d_2.mat')
    matfile3 = scipy.io.loadmat('/sharedfolder/preparation/augmented/train3d_3.mat')
    matfile4 = scipy.io.loadmat('/sharedfolder/preparation/augmented/train3d_4.mat')
    mattarget = scipy.io.loadmat('/sharedfolder/preparation/augmented/train3d_target.mat') 
       

    y_train = matfileval['test_target']
    y_train = np.concatenate((y_train,mattarget['train_target']),axis=0)
    
    X_train = matfileval['testset']
    X_train = np.concatenate((X_train,matfile1['data1']),axis=0)
    X_train = np.concatenate((X_train,matfile2['data2']),axis=0)
    X_train = np.concatenate((X_train,matfile3['data3']),axis=0)        
    X_train = np.concatenate((X_train,matfile4['data4']),axis=0)     
    X_train = X_train[0:12804,0:FS*WIN,range(feats)]
    y_train = y_train[0:12804,:] #12804
    return (X_train, y_train)

