# Feature-based approach

The feature-based approach was implemented in Matlab with the (WFDB Toolbox) as the only dependency. 

Signal processing chain is divided in the following stages:

## Preprocessing

10th order bandpass Butterworth filters with cut-off frequencies 5-45Hz (narrow band) and 1-100Hz (wide band)

## QRS detection
We used four well-known QRS detectors to each narrow-band preprocessed ECG: $gqrs$ \cite{Silva2014}, Pan-Tompkins ($jqrs$) \cite{Johnson2015challenge}, maxima search \cite{Sameni2010d}, and matched filtering. To generate a reliable consensus of QRS detection, we applied a voting system based on kernel density estimation, from which we extracted features for atrial and ventricular activity using HRV metrics and signal-quality indices. Following \cite{Acharya2006}, we calculated classical time domain, frequency domain, and non-linear HRV metrics as well as novel metrics based on clustering of beats on Poincar\'e plots. We obtained a range of signal-quality indices \cite{Li2008,Andreotti2017}, including the $bSQI$, which compares the outputs of multiple QRS detectors with agreement indicating high quality signals. In addition to features based on QRS detections, beats were delineated from wide band preprocessed signals using the $ecgpuwave$ \cite{Jane1997} for extracting morphological features such as P-wave power and QT-interval. A total of 169 features were obtained and applied on a supervised learning strategy. We used two well-known classifiers: ensemble of bagged trees (50 trees) and multilayer perceptron (2-layer, 10 hidden neurons, feed-forward). A consensus of both classifiers was used by averaging the probabilities for each class in each record.

To account for the varying length of the signals, in a second approach, we divided the preprocessed ECG signals into 10-second segments with 50\% overlap. First, we computed the features based on each segment (along each recording), and then computed the summary statistics such as mean standard deviation and min/max (for each feature), which were subsequently used in combination with bagged trees and neural network.
