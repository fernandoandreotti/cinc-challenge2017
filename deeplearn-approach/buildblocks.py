#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Jul  14 12:00:50 2017

This file contains subfunctions to be used as building blocks of deep neural 
networks. The following layers are further abstracted for simplifying main code:
    - CNN (1D/2D/Inception)
    - RNN (LSTM)
    - FC (classification/regression outputs)
    
    @author: fernando
"""
import numpy as np
from keras.layers import Conv1D, Dense, Flatten, Dropout, LSTM
from keras.layers import MaxPooling1D,AveragePooling1D, Activation, BatchNormalization, LSTM
from keras.layers.advanced_activations import PReLU
from keras.layers import  add, dot, concatenate
from keras_sequential_ascii import sequential_model_to_ascii_printout
from keras.models import load_model, Model
from keras.utils import plot_model
import keras.backend as K
import sys


""" 
############################
    Simple functions to avoid importing libraries on the main code    
############################
""" 

## Load model
def load_kerasmodel(filename):
    model = load_model(filename)
    return model

## Print model using different functions
def model_print(model):
    model.summary()
    sequential_model_to_ascii_printout(model)
    plot_model(model, to_file='model.png')
    
# Compute number of params in a model (the actual number of floats)    
def model_paramsize(model): 
    return sum([np.prod(K.get_value(w).shape) for w in model.trainable_weights])

""" 
############################
   Generate a CNN layer
   
   Input:
               model            Initialized (sequential) model
(conv)      block_type          'CNN1D', 'CNN2D', 'inception'       
(conv)      window_size         Size of window used (integer number of samples - usually second dimension of data matrix)
(conv)      nb_input_series     Number of input features (integer - usually third dimension of data matrix)
(conv)      nb_filter           Number of filters used (integer)
(conv)      kernel_size         Size of filter used (integer number of samples)
(conv)      conv_stride         Stride for convolution (integer)
(conv)      padding             Type of padding used (default 'same')
(acti)      activation_type     What activation to use (default 'relu')            
(bn)       batch_norm          Use batch normalization (boolean, default true)
(pool)      pool_type           Type of pooling max (i.e. True) or mean (i.e. False)
(pool)      pool_size           Size of pooling (integer, default 2)
(pool)      pool_stride         Stride of pooling
(drop)      dropout             Rate of dropout (float, default 50% = 0.5)
       
      
       
      batch_size=1         batch size for LSTM (RNN/RCNN only)
           
      nb_fc                number of fully connected layers used     
      fc_size              number of neurons on fully connected layers   
      nb_outputs           number of output signals, e.g. for SBP and DBP is 2
      classreg             classification (true) or regression (false) problem
############################
""" 
def add_cnn_layer(model=None,input1=None,block_type=None,window_size=1,nb_feats=1,nb_filter=10,kernel_size=10,
              padding='same',conv_stride=1,activation_type='relu',batch_norm=True,pool_type=True,pool_size=0,pool_stride=1,dropout=1):
    ### Input tests
    intvars = all(float(e).is_integer() for e in [window_size,nb_feats,nb_filter,kernel_size])
    if not intvars:
        sys.exit('ERROR! Integer arguments were expected')
        return 0
    if (dropout > 1) or (dropout < 0):
        sys.exit('ERROR! Dropout must be between 0 and 1')
        return 0
      
    if block_type in ['CNN1D','cnn1D']:
        if (input1 is None) and (model is not None):    
        ### Sequential API
            if model_paramsize(model) == 0: ## if first layer, must define input size
                model.add(Conv1D(filters=nb_filter,
                                 kernel_size=kernel_size,
                                 padding=padding,
                                 strides=conv_stride,
                                 input_shape=(window_size,nb_feats)))
            else:
                model.add(Conv1D(filters=nb_filter,
                                 kernel_size=kernel_size,
                                 padding=padding,
                                 strides=conv_stride))             
            # Batch Normalization
            if batch_norm:
                model.add(BatchNormalization())
            
            # Activation
            if activation_type is not None:
                if activation_type in ['prelu','PReLu']:
                    act = PReLU(init='zero', weights=None)
                    model.add(act)
                else: 
                    model.add(Activation(activation_type))
        
            
       
                
            # Max/Average Pooling
            if pool_size > 1:
                if pool_type:
                    model.add(MaxPooling1D(pool_size=pool_size,strides=pool_stride))
                else:
                    model.add(AveragePooling1D(pool_size=pool_size,strides=pool_stride))
            # Dropout
            if (dropout < 1) and (dropout != 0):
                model.add(Dropout(dropout))
            return model
        ### Functional API
        elif (input1 is not None) and (model is None):
            x = Conv1D(filters=nb_filter,
                       kernel_size=kernel_size,
                       padding=padding,
                       strides=conv_stride)(input1)
                            
            # Batch Normalization
            if batch_norm:
                x = BatchNormalization()(x)
            
            # Activation
            if activation_type is not None:
                if activation_type in ['prelu','PReLu']:
                    x = PReLU()(x)
                else: 
                    x = Activation(activation_type)(x)                

            
            # Max/Average Pooling
            if pool_size > 1:
                if pool_type:
                    x = MaxPooling1D(pool_size=pool_size,strides=pool_stride)(x)
                else:
                    x = AveragePooling1D(pool_size=pool_size,strides=pool_stride)(x)
            # Dropout  
            if (dropout < 1) and (dropout != 0):
                x = Dropout(dropout)(x)
            return x          
        else:
            print('ERROR! Have to decide between sequential and functional models!')   
            return 0                          
    else:
        sys.exit('Model not recognized.')   
    
    

def finish_cnn(model=None,input1=None,seq=True):
    # Flatten filters
    if seq:
        model.add(Flatten())    
        return model
    else:
        out = Flatten()(input1)
        return out



            
'''
    elif block_type in ['inception2D']:
            inception_3a_1x1 = Convolution2D(64,1,1,border_mode='same',activation='relu',name='inception_3a/1x1',W_regularizer=l2(0.0002))(pool2_3x3_s2)
            inception_3a_3x3_reduce = Convolution2D(96,1,1,border_mode='same',activation='relu',name='inception_3a/3x3_reduce',W_regularizer=l2(0.0002))(pool2_3x3_s2)
            inception_3a_3x3 = Convolution2D(128,3,3,border_mode='same',activation='relu',name='inception_3a/3x3',W_regularizer=l2(0.0002))(inception_3a_3x3_reduce)
            inception_3a_5x5_reduce = Convolution2D(16,1,1,border_mode='same',activation='relu',name='inception_3a/5x5_reduce',W_regularizer=l2(0.0002))(pool2_3x3_s2)
            inception_3a_5x5 = Convolution2D(32,5,5,border_mode='same',activation='relu',name='inception_3a/5x5',W_regularizer=l2(0.0002))(inception_3a_5x5_reduce)
            inception_3a_pool = MaxPooling2D(pool_size=(3,3),strides=(1,1),border_mode='same',name='inception_3a/pool')(pool2_3x3_s2)
            inception_3a_pool_proj = Convolution2D(32,1,1,border_mode='same',activation='relu',name='inception_3a/pool_proj',W_regularizer=l2(0.0002))(inception_3a_pool)  
            inception_3a_output = merge([inception_3a_1x1,inception_3a_3x3,inception_3a_5x5,inception_3a_pool_proj],mode='concat',concat_axis=1,name='inception_3a/output')
'''


""" 
############################
   Generate a FC layer
   
   Input:
      model               Initialized (sequential) model
      fc_size              number of neurons on fully connected layers (integer or list of integers)
      nb_outputs           number of output signals (integer)
      classreg             classification (true, default) or regression (false) problem
      activation_type      Nonlinear activation to use (default 'relu')         
      dropout              Rate of dropout (float, default 50% = 0.5)
      
############################
""" 
def add_fc_layers(model=None,fc_size=1,nb_outputs=1,classreg=True,activation_type='relu',dropout=0.5,optimizer='adam'):
    
    ## Checking inputs
    if np.size(fc_size) == 1:
        fc_size = [fc_size]
    if np.size(dropout) == 1:
        dropout = [dropout]        
    if not all(float(e).is_integer() for e in fc_size):
        sys.exit('ERROR! The number of fully conected layers must be integer.')
        return 0
    if not all((e>=0 and e<=1) for e in dropout):
        sys.exit('ERROR! The dropouts must be 0<d<1.')
        return 0
    
    ## Loop through FC layers and add to model
    for n in range(np.size(fc_size)-1):
        model.add(Dense(fc_size[n]))#,input_shape=(output_size,)))
        model.add(Dropout(dropout[n]))
        model.add(Activation(activation_type))
    
    # Final FC layer        
    model.add(Dense(nb_outputs))
    # Different activation/metrics for classification and regression
    if classreg:
        model.add(Activation('softmax'))
        model.compile(loss='categorical_crossentropy', optimizer=optimizer, metrics=['accuracy'])    
    else:        
        model.add(Activation('linear'))
        model.compile(loss='mse', optimizer=optimizer, metrics=['mae'])      
    return model
                  

'''
############################

 Recurrent Neural Networks (RNN)

   Implementation of RNN algorithms    
   
############################
'''

def add_rnn_layer(model=None,input1=None,block_type=None,rnn_size=0):
    ### Input tests
    
    ## Bidirectional RNN 
    if block_type in ['bidLSTM']:
        rnn_fwd1 = LSTM(rnn_size,input_shape=(None,1),return_sequences=True)(input1)
        rnn_bwd1 = LSTM(rnn_size,input_shape=(None,1),return_sequences=True, go_backwards=True)(input1)    
        out = concatenate([rnn_fwd1, rnn_bwd1])
        
        return out


'''
############################

 Operating with layers

  
############################
'''

def pop_layer(model):
    if not model.outputs:
        raise Exception('Sequential model cannot be popped: model is empty.')

    model.layers.pop()
    if not model.layers:
        model.outputs = []
        model.inbound_nodes = []
        model.outbound_nodes = []
    else:
        model.layers[-1].outbound_nodes = []
        model.outputs = [model.layers[-1].output]
    model.built = False
    
    
    
    
    
'''
 Callback

'''
from keras.callbacks import Callback
from keras.callbacks import warnings

class LrReducer(Callback):
    def __init__(self, patience=0, reduce_rate=0.5, reduce_nb=10, verbose=1):
        super(Callback, self).__init__()
        self.patience = patience
        self.wait = 0
        self.best_score = -1.
        self.reduce_rate = reduce_rate
        self.current_reduce_nb = 0
        self.reduce_nb = reduce_nb
        self.verbose = verbose

    def on_epoch_end(self, epoch, logs={}):
        current_score = logs.get('val_acc')
        if current_score > self.best_score:
            self.best_score = current_score
            self.wait = 0
            if self.verbose > 0:
                print('---current best val accuracy: %.3f' % current_score)
        else:
            if self.wait >= self.patience:
                self.current_reduce_nb += 1
                if self.current_reduce_nb <= 10:
                    lr = self.model.optimizer.lr.get_value()
                    self.model.optimizer.lr.set_value(lr*self.reduce_rate)
                else:
                    if self.verbose > 0:
                        print("Epoch %d: early stopping" % (epoch))
                    self.model.stop_training = True
            self.wait += 1
            

class AdvancedLearnignRateScheduler(Callback):
    
    '''
   # Arguments
       monitor: quantity to be monitored.
       patience: number of epochs with no improvement
           after which training will be stopped.
       verbose: verbosity mode.
       mode: one of {auto, min, max}. In 'min' mode,
           training will stop when the quantity
           monitored has stopped decreasing; in 'max'
           mode it will stop when the quantity
           monitored has stopped increasing.
   '''
    def __init__(self, monitor='val_loss', patience=0,verbose=0, mode='auto', decayRatio=0.1):
        super(Callback, self).__init__() 
        self.monitor = monitor
        self.patience = patience
        self.verbose = verbose
        self.wait = 0
        self.decayRatio = decayRatio
 
        if mode not in ['auto', 'min', 'max']:
            warnings.warn('Mode %s is unknown, '
                          'fallback to auto mode.'
                          % (self.mode), RuntimeWarning)
            mode = 'auto'
 
        if mode == 'min':
            self.monitor_op = np.less
            self.best = np.Inf
        elif mode == 'max':
            self.monitor_op = np.greater
            self.best = -np.Inf
        else:
            if 'acc' in self.monitor:
                self.monitor_op = np.greater
                self.best = -np.Inf
            else:
                self.monitor_op = np.less
                self.best = np.Inf
 
    def on_epoch_end(self, epoch, logs={}):
        current = logs.get(self.monitor)
        current_lr = K.get_value(self.model.optimizer.lr)
        print("\nLearning rate:", current_lr)
        if current is None:
            warnings.warn('AdvancedLearnignRateScheduler'
                          ' requires %s available!' %
                          (self.monitor), RuntimeWarning)
 
        if self.monitor_op(current, self.best):
            self.best = current
            self.wait = 0
        else:
            if self.wait >= self.patience:
                if self.verbose > 0:
                    print('\nEpoch %05d: reducing learning rate' % (epoch))
                    assert hasattr(self.model.optimizer, 'lr'), \
                        'Optimizer must have a "lr" attribute.'
                    current_lr = K.get_value(self.model.optimizer.lr)
                    new_lr = current_lr * self.decayRatio
                    K.set_value(self.model.optimizer.lr, new_lr)
                    self.wait = 0 
            self.wait += 1
