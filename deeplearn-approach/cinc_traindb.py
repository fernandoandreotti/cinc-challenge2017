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
import numpy as np
import glob

# Parameters
FS = 300
WINDOW_SIZE = 30*FS

## Searching files
dataDir = '/some_path/' # <---- change!!

files = sorted(glob.glob(dataDir+"*.mat"))

trainset = np.zeros((len(files),WINDOW_SIZE))
for f in files:
    record = f[:-4]
    record = record[-6:]
    # Loading
    mat_data = scipy.io.loadmat(f[:-4] + ".mat")
    print('Loading record {}'.format(record))    
    data = mat_data['val']
    # Preprocessing
    print('Preprocessing record {}'.format(record))       
    data = np.nan_to_num(data) # removing NaNs and Infs
    data = data[0,0:WINDOW_SIZE]
    data = data - np.mean(data)
    data = data/np.std(data)
    trainset[f,:len(data)] = data.T # padding sequence
    
#scipy.io.savemat('CNNresults.mat',mdict={'labels': answermat,'probs': probmat})