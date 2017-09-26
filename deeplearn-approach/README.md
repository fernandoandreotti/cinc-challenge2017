# Deep learning approach


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
    
    
    
# References

[3]: He, K., Zhang, X., Ren, S., & Sun, J. (2015). Deep Residual Learning for Image Recognition. arXiv Preprint arXiv:1512.03385v1, 7(3), 171–180. https://doi.org/10.3389/fpsyg.2013.00124

[4]: Rajpurkar, P., Hannun, A. Y., Haghpanahi, M., Bourn, C., & Ng, A. Y. (2017). Cardiologist-Level Arrhythmia Detection with Convolutional Neural Networks. Retrieved from http://arxiv.org/abs/1707.01836
