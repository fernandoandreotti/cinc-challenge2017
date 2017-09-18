import matplotlib.pyplot as plt
import tensorflow as tf
import numpy as np
import scipy.io
import gc
import itertools
from sklearn.metrics import confusion_matrix
import sys
sys.path.insert(0, './preparation')

# Keras imports
import keras
from keras.models import Model
from keras.layers import Input, Conv1D, Dense, Flatten, Dropout,MaxPooling1D, Activation, BatchNormalization
from keras.callbacks import EarlyStopping, ModelCheckpoint
from keras_sequential_ascii import sequential_model_to_ascii_printout
from keras.utils import plot_model
from keras import backend as K
from keras.callbacks import Callback,warnings


###################################################################
### Callback method for reducing learning rate during training  ###
###################################################################
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


###########################################
## Function to plot confusion matrices  ##
#########################################
def plot_confusion_matrix(cm, classes,
                          normalize=False,
                          title='Confusion matrix',
                          cmap=plt.cm.Blues):
    """
    This function prints and plots the confusion matrix.
    Normalization can be applied by setting `normalize=True`.
    """
    if normalize:
        cm = cm.astype('float') / cm.sum(axis=1)[:, np.newaxis]
        print("Normalized confusion matrix")
    else:
        print('Confusion matrix, without normalization')
    cm = np.around(cm, decimals=3)
    print(cm)

    thresh = cm.max() / 2.
    for i, j in itertools.product(range(cm.shape[0]), range(cm.shape[1])):
        plt.text(j, i, cm[i, j],
                 horizontalalignment="center",
                 color="white" if cm[i, j] > thresh else "black")
        
    plt.imshow(cm, interpolation='nearest', cmap=cmap)
    plt.title(title)
    plt.colorbar()
    tick_marks = np.arange(len(classes))
    plt.xticks(tick_marks, classes, rotation=45)
    plt.yticks(tick_marks, classes)
    plt.tight_layout()
    plt.ylabel('True label')
    plt.xlabel('Predicted label')



#####################################
## Model definition              ##
## ResNet based on Rajpurkar    ##
################################## 
def ResNet_model(WINDOW_SIZE):
    # Add CNN layers left branch (higher frequencies)
    # Parameters from paper
    INPUT_FEAT = 1
    OUTPUT_CLASS = 4    # output classes

    k = 1    # increment every 4th residual block
    p = True # pool toggle every other residual block (end with 2^8)
    convfilt = 64
    convstr = 1
    ksize = 16
    poolsize = 2
    poolstr  = 2
    drop = 0.5
    
    # Modelling with Functional API
    #input1 = Input(shape=(None,1), name='input')
    input1 = Input(shape=(WINDOW_SIZE,INPUT_FEAT), name='input')
    
    ## First convolutional block (conv,BN, relu)
    x = Conv1D(filters=convfilt,
               kernel_size=ksize,
               padding='same',
               strides=convstr)(input1)            
    x = BatchNormalization()(x)    
    x = Activation('relu')(x)  
    
    
    ## Second convolutional block (conv, BN, relu, dropout, conv) with residual net
    # Left branch (convolutions)
    x1 =  Conv1D(filters=convfilt,
               kernel_size=ksize,
               padding='same',
               strides=convstr)(x)  
    x1 = BatchNormalization()(x1)    
    x1 = Activation('relu')(x1)
    x1 = BatchNormalization()(x1)    
    x1 = Dropout(drop)(x1)
    x1 =  Conv1D(filters=convfilt,
               kernel_size=ksize,
               padding='same',
               strides=convstr)(x1)
    x1 = MaxPooling1D(pool_size=poolsize,
                      strides=poolstr)(x1)
    # Right branch, shortcut branch pooling
    x2 = MaxPooling1D(pool_size=poolsize,
                      strides=poolstr)(x)
    # Merge both branches
    x = keras.layers.add([x1, x2])
    del x1,x2
    
    ## Main loop
    p = not p 
    for l in range(15):
        
        if (l%4 == 0) and (l>0): # increment k on every fourth residual block
            k += 1
             # increase depth by 1x1 Convolution case dimension shall change
            xshort = Conv1D(filters=convfilt*k,kernel_size=1)(x)
        else:
            xshort = x        
        # Left branch (convolutions)
        # notice the ordering of the operations has changed
        x1 = BatchNormalization()(x)
        x1 = Activation('relu')(x1)
        x1 = Dropout(drop)(x1)
        x1 =  Conv1D(filters=convfilt*k,
               kernel_size=ksize,
               padding='same',
               strides=convstr)(x1)
        x1 = BatchNormalization()(x1)
        x1 = Activation('relu')(x1)
        x1 = Dropout(drop)(x1)
        x1 =  Conv1D(filters=convfilt*k,
               kernel_size=ksize,
               padding='same',
               strides=convstr)(x1)        
        if p:
            x1 = MaxPooling1D(pool_size=poolsize,strides=poolstr)(x1)                

        # Right branch: shortcut connection
        if p:
            x2 = MaxPooling1D(pool_size=poolsize,strides=poolstr)(xshort)
        else:
            x2 = xshort  # pool or identity            
        # Merging branches
        x = keras.layers.add([x1, x2])
        # change parameters
        p = not p # toggle pooling

    
    # Final bit
    x = BatchNormalization()(x)
    x = Activation('relu')(x) 
    x = Flatten()(x)
    x = Dense(1000)(x)
    out = Dense(OUTPUT_CLASS, activation='softmax')(x)
    model = Model(inputs=input1, outputs=out)
    model.compile(optimizer='adam',
                  loss='categorical_crossentropy',
                  metrics=['accuracy'])
    model.summary()
    sequential_model_to_ascii_printout(model)
    plot_model(model, to_file='model.png')
    return model

###########################################################
## Function to perform K-fold Crossvalidation on model  ##
##########################################################
def model_eval(X_train,y_train,model):
    batch =64
    epochs = 20  
    classes = ['A', 'N', 'O', '~']
    Kfold = 5
    Nsamp = 1705;
        
    cvconfusion = np.zeros((4,4,epochs))
    cvscores = []    
    for k in range(Kfold):
        callbacks = [
            # Early stopping definition
            EarlyStopping(monitor='val_loss', patience=3, verbose=1),
            # Decrease learning rate by 0.1 factor
            AdvancedLearnignRateScheduler(monitor='val_loss', patience=1,verbose=1, mode='auto', decayRatio=0.1),            
            # Saving best model
            ModelCheckpoint('weights-best_{}.hdf5'.format(k), monitor='val_loss', save_best_only=True, verbose=1),
            ]
        print("Cross-validation run %d"%(k+1))
        idxval = np.random.choice(8528, Nsamp,replace=False)
        idxtrain = np.invert(np.in1d(range(X_train.shape[0]),idxval))
        # Remove noise segments from training set
        ytrainset = y_train[np.asarray(idxtrain),:]
        Xtrainset = X_train[np.asarray(idxtrain),:,:]
        #yclass = np.argmax(ytrainset,axis=1)
        #ytrainset = ytrainset[np.asarray(yclass < 3),:]
        #Xtrainset = Xtrainset[np.asarray(yclass < 3),:,:]       
        model.fit(Xtrainset, ytrainset,
                  validation_data=(X_train[np.asarray(idxval),:,:], y_train[np.asarray(idxval),:]),
                  epochs=epochs, batch_size=batch,callbacks=callbacks)
                  #epochs=epochs, batch_size=batch)
                  
        ypred = model.predict(X_train[np.asarray(idxval),:,:])
        ypred = np.argmax(ypred,axis=1)
        ytrue = np.argmax(y_train[np.asarray(idxval),:],axis=1)
        cvconfusion[:,:,k] = confusion_matrix(ytrue, ypred)
        F1 = np.zeros((4,1))
        for i in range(4):
            F1[i]=2*cvconfusion[i,i,k]/(np.sum(cvconfusion[i,:,k])+np.sum(cvconfusion[:,i,k]))
            print("F1 measure for {} rhythm: {:1.4f}".format(classes[i],F1[i,0]))            
        cvscores.append(np.mean(F1)* 100)
        print("Overall F1 measure: {:1.4f}".format(np.mean(F1)))            
        K.clear_session()
        gc.collect()
        config = tf.ConfigProto()
        config.gpu_options.allow_growth=True            
        sess = tf.Session(config=config)
        K.set_session(sess)
        
    scipy.io.savemat('CNNfinal3d.mat',mdict={'cvconfusion': cvconfusion.tolist()})  
    ''' 
    # Train using whole data
    epochs = 20
    model = get_model() # reset model
    model.fit(X_train, y_train, epochs=epochs, batch_size=batch)
    '''
    return model

###########################
## Function to load data ##
###########################
def loaddata(feats,WINDOW_SIZE):    
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
    X_train = X_train[0:12804,0:WINDOW_SIZE,range(feats)]
    y_train = y_train[0:12804,:]
    return (X_train, y_train)


#####################
# Main function   ##
###################

config = tf.ConfigProto(allow_soft_placement=True)
config.gpu_options.allow_growth = True
sess = tf.Session(config=config)
seed = 7
np.random.seed(seed)


# Parameters
FS = 300
WINDOW_SIZE = 30*FS     # padding window for CNN
N_INPUT = 1


(X_train,y_train) = loaddata(N_INPUT,WINDOW_SIZE)
model = ResNet_model(WINDOW_SIZE)
model = model_eval(X_train,y_train,model)
matfile = scipy.io.loadmat('CNNfinal3d.mat')
cv = matfile['cvconfusion']
cv = cv[:,:,0:5]
cv = np.sum(cv,axis=2)
cvconfusion = cv
classes = ['A', 'N', 'O', '~']
F1 = np.zeros((4,1))
for i in range(4):
    F1[i]=2*cvconfusion[i,i]/(np.sum(cvconfusion[i,:])+np.sum(cvconfusion[:,i]))
    print("F1 measure for {} rhythm: {:1.4f}".format(classes[i],F1[i,0]))


#model = model_finetune(model,X_test,y_test)
#model.save('CNNfinal2.h5')
