#!/usr/bin/env python3
# -*- coding: utf-8 -*-
'''
Convert multiple files from Physionet/Computing in Cardiology challenge into 
file single matrix. As input argument 

For more information visit: https://github.com/fernandoandreotti/cinc-challenge2017
 
 Referencing this work
   Andreotti, F., Carr, O., Pimentel, M.A.F., Mahdi, A., & De Vos, M. (2017). Comparing Feature Based 
   Classifiers and Convolutional Neural Networks to Detect Arrhythmia from Short Segments of ECG. In 
   Computing in Cardiology. Rennes (France).

--
 cinc-challenge2017, version 1.0, Sept 2017
 Last updated : 27-09-2017
 Released under the GNU General Public License

 Copyright (C) 2017  Fernando Andreotti, Oliver Carr, Marco A.F. Pimentel, Adam Mahdi, Maarten De Vos
 University of Oxford, Department of Engineering Science, Institute of Biomedical Engineering
 fernando.andreotti@eng.ox.ac.uk
   
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
'''


import scipy.io
import os
import numpy as np
from keras.models import load_model
import glob

# Parameters
FS = 300
maxlen = 30*FS
classes = ['A', 'N', 'O']

## Searching files
dataDir = '/sharedfolder/validation/'
files = sorted(glob.glob(dataDir+"*.mat"))
print("Running classification on {} records".format(len(files)))
answermat = np.chararray((len(files),1))
probmat = np.zeros((len(files),3))
## Loading model
print("Loading model")    
model = load_model('CNNnoiseless.h5')


## Main Loop
try:
    os.remove('answers.txt')
except OSError:
    pass

count = 0
for f in files:
    record = f[:-4]
    record = record[-6:]
    # Loading
    mat_data = scipy.io.loadmat(f[:-4] + ".mat")
    print('Loading record {}'.format(record))    
    data = mat_data['val']
    # Preprocessing
    print('Preprocessing record {}'.format(record))   
    X = np.zeros((1,maxlen))
    data = np.nan_to_num(data) # removing NaNs and Infs
    data = data[0,0:maxlen]
    data = data - np.mean(data)
    data = data/np.std(data)
    X[0,:len(data)] = data.T # padding sequence
    data = X
    data = np.expand_dims(data, axis=2) # required by Keras
    del X
    # Classifying
    print("Applying model ..")    
    prob = model.predict(data)
    ann = np.argmax(prob)
    print("Record {} classified as {} with {:3.1f}% certainty".format(record,classes[ann],100*prob[0,ann]))
    answermat[count] = classes[ann]
    #probmat[count] = prob[0,0:4]
    # Write result to answers.txt
    answers_file = open("answers.txt", "a")
    answers_file.write("%s,%s\n" % (record, classes[ann]))
    answers_file.close()
    count += 1
    
#scipy.io.savemat('CNNresults.mat',mdict={'labels': answermat,'probs': probmat})