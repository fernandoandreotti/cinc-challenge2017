#!/bin/sh

# Should be platform neutral - at least working on Linux and Windows
USER_NAME=`basename $HOME`

# HHHOME is used to pass the HOME directory of the user running rodeo
# and is used in "start.sh" to create the same user within the container.
sudo xhost + local:docker

# Users home is mounted as home
# --rm will remove the container as soon as it ends
docker run -ti --rm \
     -e DISPLAY=$DISPLAY \
     -e QT_X11_NO_MITSHM=1  \
     -v /tmp/.X11-unix:/tmp/.X11-unix \
     -v `pwd`:/sharedfolder \
     andreotti/challenge2017:cpu


