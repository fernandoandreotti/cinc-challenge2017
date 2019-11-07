[![license](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](./LICENSE)
[![PWC](https://img.shields.io/endpoint.svg?url=https://paperswithcode.com/badge/comparing-feature-based-classifiers-and/arrhythmia-detection-on-the-physionet)](https://paperswithcode.com/sota/arrhythmia-detection-on-the-physionet?p=comparing-feature-based-classifiers-and)

## ECG classification from single-lead segments using _Deep Convolutional Neural Networks_ and _Feature-Based Approaches_

#### Our entry for the Computing in Cardiology Challenge 2017: Atrial Fibrillation (AF) Classification from a short single lead Electrocardiogram (ECG) recording

When using this code, please cite [our paper](http://prucka.com/2017CinC/pdf/360-239.pdf): 

> Andreotti, F., Carr, O., Pimentel, M.A.F., Mahdi, A., & De Vos, M. (2017). Comparing Feature Based Classifiers and Convolutional Neural Networks to Detect Arrhythmia from Short Segments of ECG. In Computing in Cardiology. Rennes (France).


This repository contains our solution [1] to the Physionet Challenge 2017 presented at the Computing in Cardiology conference 2017. As part of the Challenge, based on short single-lead ECG segments with 10-60 seconds duration, the classifier should output one of the following classes:

| Class  | Description |
| ----- | -------------------:|
| N | normal sinus rhythm |
| A | atrial fibrillation (AF) |
| O | other cardiac rhythms |
| ~ | noise segment |


Two methodologies are proposed and described in distict forlder within this repo:

* Classic feature-based MATLAB approach (`featurebased-approach` folder)
* Deep Convolutional Network Approach in Python (`deeplearn-approach` folder)


## Downloading Challenge data

For downloading the [challenge training set](https://physionet.org/challenge/2017/training2017.zip). This can be done on Linux using:

```bash
wget https://physionet.org/challenge/2017/training2017.zip
unzip training2017.zip
```

## Acknowledgment
All authors are affilated at the Institute of Biomedical Engineering, Department of Engineering Science, University of Oxford.


## License

Released under the GNU General Public License v3

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/.

## References

When using this code, please cite [1].

[1]: Andreotti, F., Carr, O., Pimentel, M.A.F., Mahdi, A., & De Vos, M. (2017). Comparing Feature Based Classifiers and Convolutional Neural Networks to Detect Arrhythmia from Short Segments of ECG. In Computing in Cardiology. Rennes (France).

[2]: Clifford, G.D., Liu, C., Moody, B., Silva, I., Li, Q., Johnson, A.E.W., & Mark, R.G. (2017). AF Classification from a Short Single Lead ECG Recording: the PhysioNet Computing in Cardiology Challenge 2017. In Computing in Cardiology. Rennes (France).
