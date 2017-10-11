FROM ubuntu:14.04
MAINTAINER Fernando Andreotti <fernando.andreotti@eng.ox.ac.uk>

# Versions used for some packages
ARG CONDA_VERSION=4.3.1
ARG CONDA_ENV
ARG TENSORFLOW_VERSION=1.0*
ARG KERAS_VERSION=2.0.2
ARG PYTHON_VERSION=3.5

ENTRYPOINT ["/bin/bash", "-c" ]

USER root

# Install some dependencies
ENV DEBIAN_FRONTEND noninteractive
ENV CONDA_ENV_PATH /opt/miniconda
ENV MYCONDA_ENV "deeplearn"
ENV CONDA_ACTIVATE "source $CONDA_ENV_PATH/bin/activate $MYCONDA_ENV"

RUN apt-get update --fix-missing -qq \
     && apt-get install --no-install-recommends -y \
		autoconf \
		automake \  
		bc \
		build-essential \
		bzip2 \
		cmake \
		curl \
		g++ \
		gfortran \
		git \
		language-pack-en \
		libatlas-dev \
		libatlas3gf-base \
		libcurl4-openssl-dev \ 
		libffi-dev \
		libfreetype6-dev \
		libglib2.0-0 \   
		libhdf5-dev \
		liblcms2-dev \
		libopenblas-dev \		
		libssl-dev \
		libtiff5-dev \
		libtool \
		libwebp-dev \
		libzmq3-dev \
		make \
		nano \
		pkg-config \
		software-properties-common \
		unzip \
		wget \
		zlib1g-dev \
		qt5-default \
		libvtk6-dev \
		zlib1g-dev

# Install miniconda to /opt/miniconda
RUN curl -LO http://repo.continuum.io/miniconda/Miniconda-latest-Linux-x86_64.sh
RUN /bin/bash Miniconda-latest-Linux-x86_64.sh -p $CONDA_ENV_PATH -b
RUN rm Miniconda-latest-Linux-x86_64.sh
ENV PATH=$CONDA_ENV_PATH/bin:${PATH}
RUN conda update --quiet --yes conda

ENV PATH ${CONDA_ENV_PATH}/bin:$PATH

# Creating Anaconda environment
RUN conda create -y --name $MYCONDA_ENV python=${PYTHON_VERSION}

# Install Python 3 packages

RUN conda install -c conda-forge -y -n $MYCONDA_ENV\
     'beautifulsoup4=4.5*' \
    'hdf5=1.8.17' \
    'h5py=2.7*' \
    'ipython=5.1*' \	
    'ipykernel=4.5*' \
    'ipywidgets=5.2*' \
    'jupyter=1.0*' \
    'lxml=3.8*' \
    'matplotlib=2.0*' \
    'notebook=4.3*' \
    'numpy=1.12*' \
    'pandas=0.20*' \
    'pillow=4.2*' \
    'pip=9.0*' \
    'python=3.5*' \
    'rpy2=2.8*'  \
    'scipy=0.19*' \
    'scikit-learn=0.19*' \
    'scikit-image=0.13*' \
    'setuptools=36.3*' \
    'six=1.10*' \
    'sphinx=1.5*' \
    'spyder=3.1*'  && \
    conda clean -tipsy

# Some R dependencies
RUN conda install -c conda-forge -n $MYCONDA_ENV r-r.utils r-lme4 r-nlme

# Install TensorFlow
RUN conda install -c conda-forge -n $MYCONDA_ENV tensorflow=${TENSORFLOW_VERSION}


# Install Keras
ENV KERAS_BACKEND=tensorflow
RUN conda install -c conda-forge -n $MYCONDA_ENV keras=${KERAS_VERSION}

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

RUN conda info --envs
RUN sed -i 's/theano/tensorflow/g' ${CONDA_ENV_PATH}/envs/${MYCONDA_ENV}/etc/conda/activate.d/keras_activate.sh # make tensorflow default 

# Visualization tools
RUN conda install -c conda-forge -y -n $MYCONDA_ENV \
	graphviz=2.38.0 \
	pydotplus=2.0.2



RUN $CONDA_ACTIVATE && pip install --upgrade pip && \
	pip install git+git://github.com/stared/keras-sequential-ascii.git \
	pydot3

####################
## Running tests ###
####################

ENV HOME /sharedfolder
WORKDIR /sharedfolder

# Add a notebook profile.
RUN mkdir -p -m 700 /sharedfolder/.jupyter/ && \
	echo "c.NotebookApp.ip = '*'" >> /sharedfolder/.jupyter/jupyter_notebook_config.py \
	echo "c.NotebookApp.port = 8888" >> /sharedfolder/.jupyter/jupyter_notebook_config.py \
	echo "c.NotebookApp.open_browser = False" >> /sharedfolder/.jupyter/jupyter_notebook_config.py \
	echo "c.MultiKernelManager.default_kernel_name = 'python3'" >> /sharedfolder/.jupyter/jupyter_notebook_config.py \
	echo "c.NotebookApp.allow_root = True" >> /sharedfolder/.jupyter/jupyter_notebook_config.py \
	echo "c.NotebookApp.password_required = False" >> /sharedfolder/.jupyter/jupyter_notebook_config.py \
	echo "c.NotebookApp.token = ''" >> /sharedfolder/.jupyter/jupyter_notebook_config.py


# Expose Ports for TensorBoard (6006), Ipython (8888)
EXPOSE 6006 8888

CMD ["source activate deeplearn && /bin/bash"]
