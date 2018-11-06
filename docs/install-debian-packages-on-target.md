# Install Debian Packages on Target

This guide shows how to start a container, install some packages and modify the
container such that it will start a Python script on startup.

This steps and image modifications should be done in a Dockerfile for
reproducability. Executing those steps manually can be useful to develop
the Dockerfile or for quick prototyping.

## Start a base Debian container

To pull an execute a Debian container interactively use the docker run command.
This starts the container privileged and with devices available inside the
container. This allows to access the hardware (e.g. graphics in this case)
directly from inside the container.

```bash
docker run -it --privileged -v /dev:/dev debian:buster /bin/bash
```

This starts a new container interactively which can be used to build a new image
interactively.

This drops us in a prompt with root privileges
```bash
root@3887607ebf2a:/#
```

## Install Debian packages

With this prompt, use the typical commands to install Debian packages. This
example installs [Qt for Python](https://wiki.qt.io/Qt_for_Python), also known
as PySide2.

```bash
apt-get update
apt-get install --no-install-recommends vim-tiny python3-pyside2.qtwidgets \
                python3-pyside2.qtgui python3-pyside2.qtcore
```

This will install a bunch of packages and takes a while.

## Create a Qt for Python Hello World example

Create a small Hello World python script:

```bash
vi qtdemo.py
```

Press `i`, insert the code below and exit with escape, `:wq`.

```
import sys
from PySide2.QtWidgets import QApplication, QLabel
 
if __name__ == "__main__":
    app = QApplication(sys.argv)
    label = QLabel("Hello World")
    label.show()
    sys.exit(app.exec_())
```

At this point we can't execute the script manually by setting up the Qt
environment to access the graphics hardware directly:

```bash
export QT_QPA_PLATFORM=linuxfb
export QT_QPA_FB_DRM=1
python3 /qtdemo.py
```

## Create a Docker image from a Container

Now lets stop the container by exiting the shell and create a Docker image from
that container. The container ID is the part after `root@` from the prompt, or
can be obtained from docker ps:

```bash
docker ps -a
...
```

Now docker commit can be used to create a Docker image. The `--change` parameter
can be used to customize the container:

```bash
docker commit --change='ENV QT_QPA_PLATFORM=linuxfb' \
              --change='ENV QT_QPA_FB_DRM=1' \
              --change='ENTRYPOINT ["python3", "/qtdemo.py"]' \
              3887607ebf2a debian-qtdemo
```

Then create a container from the image. Use the `--restart=always` parameter to
make sure that the container get started on system boot.

```bash
docker run -d -it --restart=always --privileged \
       -v /dev:/dev debian-qtdemo
```
