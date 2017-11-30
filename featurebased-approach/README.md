# Feature-based approach

This approach makes use of several previously described heart rate variability metrics, morphological features and signal quality indices. After extracting features, two classifiers are trained,namely, an ensemble of bagged trees (50 trees) and multilayer perceptron (2-layer, 10 hidden neurons, feed-forward).

## Dependencies

This code was tested on Matlab R2017a (Version 9.2) with the [WFDB Toolbox for Matlab/Octave v0.9.8](https://physionet.org/physiotools/matlab/wfdb-app-matlab/) as the only dependency. Please refer to the toolbox's website for how to install.

## Getting started

`ExtractFeatures()` performs feature extraction for each record within a folder

`SegmentClassifier()` trains an Ensemble of Bagged Decision Trees and Multilayer Perceptron Classifier to classify segments of ECG into the defined categories.


## Description of approach

Signal processing chain is divided in the following stages:

### Preprocessing

10th order bandpass Butterworth filters with cut-off frequencies 5-45Hz (narrow band) and 1-100Hz (wide band)

### QRS detection
We used four well-known QRS detectors: 

- gqrs (WFDB Toolbox)
- Pan-Tompkins (FECGSYN) 
- Maxima Search (OSET/FECGSYN)
- matched filtering

A consensus based on kernel density estimation is output as final decision.

### Feature Extraction

| Type  | Examples | Number |
| -------- | ------------------- | ----:|
| Time Domain | SDNN, RMSSD, NNx | 8 |
| Frequency Domain | LF power, HF power, LF/HF | 8 |
| Non-linear Features | Poincaré plot, Recurrence Quantification Analysis | 95 |
| Signal Quality | bSQI, iSQI, kSQI, rSQI | 36 |
| Morphological Features | P-wave power, T-wave power, QT interval | 22 |
|  | Total | 169 |


