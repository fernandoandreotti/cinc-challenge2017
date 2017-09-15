# Computing in Cardiology Challenge 2017
### Atrial Fibrillation (AF) Classification from a short single lead Electrocardiogram (ECG) recording

This repository contains the solution to the CinC Challenge 2017 by [1], presented at the Computing in Cardiology conference 2017. As part of the Challenge, based on short single-lead ECG segments with 10-60 seconds duration, the classifier should output one of the following classes:

| Class  | Description |
| ----- | -------------------:|
| N | normal sinus rhythm |
| A | atrial fibrillation (AF) |
| O | other cardiac rhythms |
| ~ | noise segment |


Two methodologies are proposed and are available on distict forlder in this repo:

* Classic feature-based MATLAB approach (`featurebased-approach` folder)
* Deep Convolutional Network Approach in Python (`deeplearn-approach` folder)


Here follows quickstart information about each approach.


Feature-based Approach (MATLAB)
---

This approach makes use of several previously described heart rate variability metrics, morphological features and signal quality indices. After extracting features, two classifiers are trained,namely, an ensemble of bagged trees (50 trees) and multilayer perceptron (2-layer, 10 hidden neurons, feed-forward).

#### Dependencies

This code was tested on Matlab R2017a (Version 9.2). 

WFDB Toolbox for Matlab/Octave


Deep Convolutional Neural Network (CNN) Approach (Python)
---


#### Dependencies

Random text

**Docker**

Random text




# Acknowledgment
All authors are affilated at the Institute of Biomedical Engineering, Department of Engineering Science, University of Oxford.

# References

When using this code, please cite [1].

[1]: Andreotti, F., Carr, O., Pimentel, M.A.F., Mahdi, A., & De Vos, M. (2017). Comparing Feature Based Classifiers and Convolutional Neural Networks to Detect Arrhythmia from Short Segments of ECG. In Computing in Cardiology. Rennes (France).

[2]: Clifford, G.D., Liu, C., Moody, B., Silva, I., Li, Q., Johnson, A.E.W., & Mark, R.G. (2017). AF Classification from a Short Single Lead ECG Recording: the PhysioNet Computing in Cardiology Challenge 2017. In Computing in Cardiology. Rennes (France).


