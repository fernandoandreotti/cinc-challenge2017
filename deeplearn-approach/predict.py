su#!/usr/bin/env python3

## old one !/usr/bin/python3
import sys
import scipy.io
record = sys.argv[1]

# Read waveform samples (input is in WFDB-MAT format)
mat_data = scipy.io.loadmat(record + ".mat")
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
model = load_model('ResNetmodel.h5')
print("Applying model ..")    
prob = model.predict(data)
ann = np.argmax(prob)
print("Record {} classified as {} with {:3.1f}% certainty".format(record,classes[ann],100*prob[0,ann]))    


# Write result to answers.txt
answers_file = open("answers.txt", "a")
answers_file.write("%s,%s\n" % (record, classes[ann]))
answers_file.close()
