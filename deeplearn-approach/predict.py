'''
This function loads one random recording from CinC Challenge and use pre-trained model in predicting what it is using Residual Networks

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

# Visualising output of first 16 convolutions for some layers
from keras import backend as K
import matplotlib.pyplot as plt
plt.plot(data[0,0:1000,0],)
plt.title('Input signal')
#plt.savefig('layinput.eps', format='eps', dpi=1000) # saving?

for l in range(1,34):#range(1,34):
    Np = 1000
    ## Example of plotting first layer output
    layer_name = 'conv1d_{}'.format(l)
    layer_dict = dict([(layer.name, layer) for layer in model.layers])
    layer_output = layer_dict[layer_name].output
    
    # K.learning_phase() is a flag that indicates if the network is in training or
    # predict phase. It allow layer (e.g. Dropout) to only be applied during training
    get_layer_output = K.function([model.layers[0].input, K.learning_phase()],
                                   [layer_output])
    filtout = get_layer_output([data,0])[0]
    Npnew = int(Np*filtout.shape[1]/data.shape[1])
    fig, ax = plt.subplots(nrows=4, ncols=4, sharex='col', sharey='row')    
    count = 0
    for row in ax:
        for col in row:
            col.plot(range(Npnew), filtout[0,0:Npnew,count],linewidth=1.0,color='olive')
            count += 1
    plt.suptitle('Layer {}'.format(l))
    #plt.savefig('layoutput{}.eps'.format(l), format='eps', dpi=1000) # saving?
            


