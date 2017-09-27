# ECG classification from single lead short segments
### Computing in Cardiology Challenge 2017: Atrial Fibrillation (AF) Classification from a short single lead Electrocardiogram (ECG) recording

This repository contains our solution to the Physionet Challenge 2017 by [1], presented at the Computing in Cardiology conference 2017. As part of the Challenge, based on short single-lead ECG segments with 10-60 seconds duration, the classifier should output one of the following classes:

| Class  | Description |
| ----- | -------------------:|
| N | normal sinus rhythm |
| A | atrial fibrillation (AF) |
| O | other cardiac rhythms |
| ~ | noise segment |


Two methodologies are proposed and described in distict forlder within this repo:

* Classic feature-based MATLAB approach (`featurebased-approach` folder)
* Deep Convolutional Network Approach in Python (`deeplearn-approach` folder)


# Downloading Challenge data

For downloading the challenge using `wget` in Linux or Mac use:

```bash
wget -r -np http://www.physionet.org/physiobank/database/challenge/2017/training/
cd physionet.org; mkdir training
find . -name \*.mat -exec cp {} training/ \;
cd ..; cp -R physionet.org/training/* training/
rm -R physionet.org
```

# Acknowledgment
All authors are affilated at the Institute of Biomedical Engineering, Department of Engineering Science, University of Oxford.

# References

When using this code, please cite [1].

[1]: Andreotti, F., Carr, O., Pimentel, M.A.F., Mahdi, A., & De Vos, M. (2017). Comparing Feature Based Classifiers and Convolutional Neural Networks to Detect Arrhythmia from Short Segments of ECG. In Computing in Cardiology. Rennes (France).

[2]: Clifford, G.D., Liu, C., Moody, B., Silva, I., Li, Q., Johnson, A.E.W., & Mark, R.G. (2017). AF Classification from a Short Single Lead ECG Recording: the PhysioNet Computing in Cardiology Challenge 2017. In Computing in Cardiology. Rennes (France).
