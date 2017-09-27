#!/usr/bin/env python3

# Download some random waveform from challenge database
from random import randint
import urllib.request
record = "A{:05d}".format(randint(0, 999))
urlfile = "https://www.physionet.org/physiobank/database/challenge/2017/training/A00/{}.mat".format(record)
local_filename, headers = urllib.request.urlretrieve(urlfile)
html = open(local_filename)
print('Downloading record {} ..'.format(record))
   
# Load data
import scipy.io
mat_data = scipy.io.loadmat(local_filename)
data = mat_data['val']

# Parameters
FS = 300
maxlen = 30*FS
classes = ['A', 'N', 'O','~']

# Preprocessing data
print("Preprocessing recording ..")    
import numpy as np
X = np.zeros((1,maxlen))
data = np.nan_to_num(data) # removing NaNs and Infs
data = data[0,0:maxlen]
data = data - np.mean(data)
data = data/np.std(data)
X[0,:len(data)] = data.T # padding sequence
data = X
data = np.expand_dims(data, axis=2) # required by Keras
del X


# Load and apply model
print("Loading model")    
from keras.models import load_model
model = load_model('ResNet_30s_34lay_16conv.hdf5')
print("Applying model ..")    
prob = model.predict(data)
ann = np.argmax(prob)
print("Record {} classified as {} with {:3.1f}% certainty".format(record,classes[ann],100*prob[0,ann]))
