# TorizonCore Getting Started Guide

## Installation

TorizonCore is installed via the [Toradex Easy Installer](https://developer.toradex.com/software/toradex-easy-installer). The latest builds can be obtained by enabling the **Toradex Continous Integration Server** feed in the Toradex Easy Installer Feeds dialog. We currently have three flavors of images:

* torizon-core-docker: A full featured image containing docker and OTA.
* torizon-core-balena: Similar to the above but with Balena instead of docker for a smaller footprint.
* torizon-core-lite: A minimal image only containing OTA.

As of now the following machines are supported:
* Colibri i.MX7 (raw NAND & eMMC)
* Colibri i.MX6
* Apalis i.MX6

## Features

The full image is quite minimal featuring basic command line utilities. The main points are [OSTree](https://ostree.readthedocs.io/en/latest/) and [Docker](https://www.docker.com/) support. OSTree allows updating the root filesystem transactionally and incrementally. Another experimental feature in the image is tooling to make use of device tree overlays. The kernel itself is following mainline (Linux 4.19). There is no package management in the base system. Docker containers can be used to acquire other needed features. The minimal image is even more bare-bones containing just the bare minimum to support OTA+.

Upon booting one can login using the following users:
* login: root (only on serial console)

  password: n/a

* login: torizon

  password: torizon

### Device Tree Overlays

The traditional device tree process was a slog of editing the source file, compiling it, then deploying the binary to the device and testing your changes. With Torizon we hope to somewhat streamline this process with the use of device tree overlays. With overlays now you only have to create a smaller snippet with the hardware changes you need.

There will also be tooling provided to allow you to edit and compile device tree files on device. Deployment has also been streamlined letting you deploy these overlays from the device and only requiring a quick reboot to review your changes. For more information on this provided tooling check this article [here](docs/device-tree-and-overlays.md).

### Containers

Along with TorizonCore we provide a default container as a sort of friendly starting environment. The container is Debian buster release based featuring an X-Server desktop as well as a internet browser. To download this container enter the following:
  
```
docker run -d -it --restart=always --privileged -v /var/run/dbus:/var/run/dbus \
       -v /dev:/dev bclouser/debian-lxde:buster startx
```

This will ask Docker to run a container using the `bclouser/debian-lxde` image. Since the image is not preinstalled, it will get downloaded from Docker Hub and installed on the module. This will require internet connection on the device and make take a few minutes. It will start a Debian environment (HDMI on i.MX6, parallel RGB on i.MX 7). Connecting to the device over serial/ssh will allow access to the base TorizonCore console.

To get a second shell inside the container `docker exec` can be used as such:

```
colibri-imx6:~$ docker ps
CONTAINER ID        IMAGE                             COMMAND                  CREATED             STATUS
c696a76d3021        bclouser/debian-lxde-x11:buster   "/usr/bin/entry.sh s…"   11 minutes ago      Up 11 minutes
colibri-imx6:~$ docker exec -it c696 /bin/bash
```

In the case of devices with smaller storage the full debian container may be too large to run. Resin.io offers minimal Debian images on Docker Hub at [resin/armv7hf-debian](https://hub.docker.com/r/resin/armv7hf-debian/tags/). These should be small enough to run on more limited devices.

```
docker run -it resin/armv7hf-debian /bin/bash
```

### OSTree/OTA

TorizonCore is built with OSTree a shared library and suite of command line tools that combines a "git-like" model for committing and downloading bootable filesystem trees, along with a layer for deploying them and managing the bootloader configuration". In short this image has the foundation for OTA (over-the-air) update capabilities.

Torizon Update System reuses what Linux microPlatform and meta-updater are providing. You can find more about the OTA strategy on the [foundries.io Blog](https://foundries.io/insights/2018/05/25/ota-part-1/).

Here's a quick demo on performing an update using the underlaying OSTree technologoy on the device manually.

Whenever you build TorizonCore a directory `ostree_repo` gets produced during the build. This directory is git-like containing the meta-data for that build's filesystem. Toradex uploads the nightly build OSTree repository and makes it available at http://feeds.toradex.com/ostree/nightly/apalis-imx6/.

Using OSTree I can add this repository like how one would add a remote git repo.
```
ostree remote add --no-gpg-verify toradex-nightly \
       http://feeds.toradex.com/ostree/nightly/apalis-imx6/

```

```
apalis-imx6:~# ostree remote refs toradex-nightly
toradex-nightly:torizon-core-balena
toradex-nightly:torizon-core-docker
toradex-nightly:torizon-core-lite
```

Following standard git procedure you'd then perform a pull.
```
root@apalis-imx6:~# ostree pull toradex-nightly:torizon-core-docker
172 metadata, 485 content objects fetched; 17704 KiB transferred in 12 seconds 
```

Next you queue the commit for deployment upon next boot
```
root@apalis-imx6:~# ostree admin deploy toradex-nightly:torizon-core-docker
Copying /etc changes: 5 modified, 2 removed, 7 added
Transaction complete; bootconfig swap: yes; deployment count change: 1
```

OSTree shows that there is a switch to a new tree pending
```
root@apalis-imx6:~# ostree admin status
  torizon 0cbeafe2973079d5edb4457839054af3c1bb8ea09678c92bcf022eea2ca92e60.0 (pending)
    origin refspec: toradex-nightly:torizon-core-docker
* torizon 4fc80f14d5ee2160004e3252080226f8f1d6f6ad4d8d7024b4198584c23afaa6.0
    origin refspec: 4fc80f14d5ee2160004e3252080226f8f1d6f6ad4d8d7024b4198584c23afaa6
```

After a quick reboot you can see the new OSTree active

Finally, you can view your current and previous deployment which you can rollback to if need be.
```
root@apalis-imx6:~# ostree admin status
* torizon 0cbeafe2973079d5edb4457839054af3c1bb8ea09678c92bcf022eea2ca92e60.0
    origin refspec: toradex-nightly:torizon-core-docker
  torizon 4fc80f14d5ee2160004e3252080226f8f1d6f6ad4d8d7024b4198584c23afaa6.0 (rollback)
    origin refspec: 4fc80f14d5ee2160004e3252080226f8f1d6f6ad4d8d7024b4198584c23afaa6
```

### Building TorizonCore

To build/develop TorizonCore follow the README [here](docs/building-torizon.md) to set up your build environment.


## Known Problems/Issues

* Image Space limitation

  The full featured image is rather large taking up most of the space on the Colibri i.MX7 raw NAND. As such it is not recommended to experiment with containers on this device since there isn't much space for containers as is. In the future we hope to slim down the footprint. Alternativley, the Balena based image is slimmer by about ~70MB.

* Xorg video driver

  In our i.MX6 Debian containers we are using the [Armada X.org DDX driver](http://git.arm.linux.org.uk/cgit/xf86-video-armada.git/) which seems to have worked fine in our tests but, it might show stability issues.

 
* Error "No session for pid" on container startup

   The error is probably related to missing session management inside the container.

* Image not booting properly

   Make sure to clear the U-Boot environment by using `env default -a && env save`.
