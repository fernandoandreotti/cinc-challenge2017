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

# Installing

# Downloading Challenge data

```bash
wget -r -np http://www.physionet.org/physiobank/database/challenge/2017/training/
find . -name physionet.org\*.mat -exec cp {} training \;
rm -R physionet.org
```


Here follows quickstart information about each approach.
Feature-based Approach (MATLAB)
---

This approach makes use of several previously described heart rate variability metrics, morphological features and signal quality indices. After extracting features, two classifiers are trained,namely, an ensemble of bagged trees (50 trees) and multilayer perceptron (2-layer, 10 hidden neurons, feed-forward).

## Dependencies

This code was tested on Matlab R2017a (Version 9.2). 

WFDB Toolbox for Matlab/Octave


Deep Convolutional Neural Network (CNN) Approach (Python)
---

Residual Networks (ResNet) [3] are an architecture of CNNs that have produced excelent results in computer vision. Recently, Rajpurkar _et al._ [4] applied a 34-layer ResNet (very similar to the one proposed by [3]) to classify 30-s single lead ECGs segments into 14 different classes. This network is reproduced in this work, implemented using Keras framework with Tensorflow as backend.

## Dependencies

The following packages were used to match the Challenge Sandbox environment:

- Python v3.5
- Tensorflow v1.0.0
- Keras v2.0.2

### Docker

To facilitate the reproduction of our network, a Docker [(what is Docker?)](https://www.docker.com/what-docker) image of the system architecture for running this code is made available under https://hub.docker.com/r/andreotti/challenge2017/ . The image was generated for CPU and GPUs machine, just modify `<system_architecture>` to `cpu` or `gpu` accordingly.

To pull the Docker image use:
```bash
docker pull andreotti/challenge2017:<system_architecture>
```
      
To run this image using Jupyter notebook, you should copy the contents of the `deeplearn-approach` folder into a `<LOCAL_FOLDER>` and use the following code:

**CPU Version**
```bash
docker run -it -p 8888:8888 -p 6006:6006 -v <LOCAL_FOLDER>:/sharedfolder andreotti/challenge2017:cpu
```
	
**GPU Version**
```bash
nvidia-docker run -it -p 8888:8888 -p 6006:6006 -v <LOCAL_FOLDER>:/sharedfolder andreotti/challenge2017:gpu
```

Then the following line will start the Jupyter notebook on the Docker and give you a URL to follow on your machine's browser:

    jupyter notebook --ip=0.0.0.0 --no-browser 


# Acknowledgment
All authors are affilated at the Institute of Biomedical Engineering, Department of Engineering Science, University of Oxford.

# References

When using this code, please cite [1].

[1]: Andreotti, F., Carr, O., Pimentel, M.A.F., Mahdi, A., & De Vos, M. (2017). Comparing Feature Based Classifiers and Convolutional Neural Networks to Detect Arrhythmia from Short Segments of ECG. In Computing in Cardiology. Rennes (France).

[2]: Clifford, G.D., Liu, C., Moody, B., Silva, I., Li, Q., Johnson, A.E.W., & Mark, R.G. (2017). AF Classification from a Short Single Lead ECG Recording: the PhysioNet Computing in Cardiology Challenge 2017. In Computing in Cardiology. Rennes (France).

[3]: He, K., Zhang, X., Ren, S., & Sun, J. (2015). Deep Residual Learning for Image Recognition. arXiv Preprint arXiv:1512.03385v1, 7(3), 171–180. https://doi.org/10.3389/fpsyg.2013.00124

[4]:Rajpurkar, P., Hannun, A. Y., Haghpanahi, M., Bourn, C., & Ng, A. Y. (2017). Cardiologist-Level Arrhythmia Detection with Convolutional Neural Networks. Retrieved from http://arxiv.org/abs/1707.01836

