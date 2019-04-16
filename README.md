# TorizonCore Getting Started Guide

## Installation

TorizonCore is installed via the [Toradex Easy Installer](https://developer.toradex.com/software/toradex-easy-installer). The latest builds can be obtained by enabling the **Toradex Continous Integration Server** feed in the Toradex Easy Installer Feeds dialog. We currently have three flavors of images:

* torizon-core-docker: A full-featured image containing Docker and OTA. All other instructions on this page require this image.
* torizon-core-balena: Similar to the above but with Balena instead of Docker for a smaller footprint. Currently this image is in evaluation and might be dropped in the future.
* torizon-core-lite: A minimal image only containing OTA. Can serve as a base for customers building custom images using OpenEmbedded and planing to leverage TorizonCore update system.

As of now, the following machines are supported:
* Colibri i.MX7 (eMMC and raw NAND*)
* Colibri i.MX6
* Colibri i.MX6ULL*
* Apalis i.MX6

*raw NAND-based modules are currently supported only by experimental releases and they may not be supported in the stable versions of TorizonCore.

## Features

The full image is quite minimal featuring basic command line utilities. The main points are [OSTree](https://ostree.readthedocs.io/en/latest/) and [Docker](https://www.docker.com/) support. OSTree allows updating the root filesystem transactionally and incrementally. Another experimental feature in the image is tooling to make use of device tree overlays. The kernel itself is following mainline (Linux 4.20). There is no package management in the base system. Docker containers can be used to acquire other features. The minimal image is even more bare-bones containing just the bare minimum to support OTA+.

Upon booting one can login using the following users:

* login: root
  * password: (none)
  * Only active on serial console!

* login: torizon
  * password: torizon
  * Available on SSH/serial console

### Device Tree Overlays

The traditional device tree process was a slog of editing the source file, compiling it, then deploying the binary to the device and testing your changes. With Torizon we hope to somewhat streamline this process with the use of device tree overlays. With overlays you now only have to create a smaller snippet with the hardware changes you need.

There will also be tooling provided to allow you to edit and compile device tree files on device. Deployment has also been streamlined letting you deploy these overlays from the device and only requiring a quick reboot to review your changes. For more information on this provided tooling check this article [here](docs/device-tree-and-overlays.md).

### Containers

Along with TorizonCore we provide a default container as a sort of friendly starting environment. 

#### Debian with Weston Wayland compositor

The container is Debian buster release based featuring the Weston Wayland compositor. To download this container enter the following:

```
docker run -d -it --restart=always --privileged -v /tmp:/tmp \
       torizon/arm32v7-debian-weston:buster weston-launch --tty=/dev/tty7 --user=root
```

Note: Currently Weston requires an input device being available (e.g. USB Keyboard/Mouse).

This will ask Docker to run a container using the `torizon/debian-lxde` image. Since the image is not preinstalled, it will get downloaded from Docker Hub and installed on the module. This will require internet connection on the device and make take a few minutes. It will start Weston (HDMI on Apalis iMX6, parallel RGB on Colibri iMX6/iMX7). Connecting to the device over serial/ssh will allow access to the base TorizonCore console.

On modules without GPU like Colibri iMX7/iMX6ULL use `weston-launch --tty=/dev/tty7 --user=root -- --use-pixman` to start Weston with Pixman.

Weston creates a unix socket file (typically `0-runtime-dir`) in /tmp. By bind mounting /tmp into a second container, a Wayland client application can access the Wayland compositor despite being in separate containers. The Wayland client application will talk to Weston (the Wayland Compositor) through the unix socket file and draw in a window on Weston. E.g. this example reuses the same image to run a second container, but this time using `es2gears_wayland`.

```
docker run -d -it --restart=always --privileged -v /tmp:/tmp \
       torizon/arm32v7-debian-weston:buster es2gears_wayland
```

To get a shell inside the container `docker exec` can be used:

```
colibri-imx6:~$ docker ps
CONTAINER ID   IMAGE                                  COMMAND                  CREATED         STATUS
61b85bc37644   torizon/arm32v7-debian-weston:buster   "/usr/bin/entry.sh w…"   2 hours ago     Up 2 hours
colibri-imx6:~$ docker exec -it 61b8 /bin/bash
```

This will create a prompt with root privileges inside the container.

#### Debian with LXDE and X.org

The container is Debian buster release based featuring an X-Server desktop as well as an internet browser. To download this container enter the following:

```
docker run -d -it --restart=always --privileged -v /var/run/dbus:/var/run/dbus \
       -v /dev:/dev torizon/debian-lxde:buster startx
```

This will run a container using the `torizon/debian-lxde` image. It will start a Debian LXDE environment (HDMI on i.MX6, parallel RGB on i.MX 7). Connecting to the device over serial/ssh will allow access to the base TorizonCore console.

The article [Install Debian Packages on Target](docs/install-debian-packages-on-target.md) shows how to install Debian packages on the target and create a new Docker image from it.

### OSTree/OTA

TorizonCore is built with OSTree a shared library and suite of command line tools that combines a "git-like" model for committing and downloading bootable filesystem trees, along with a layer for deploying them and managing the bootloader configuration". In short, this image has the foundation for OTA (over-the-air) update capabilities.

Torizon Update System reuses what Linux microPlatform and meta-updater are providing. You can find more about the OTA strategy on the [foundries.io Blog](https://foundries.io/insights/2018/05/25/ota-part-1/).

Here's a quick demo on performing an update using the underlying OSTree technology on the device manually.

Please notice that all device commands must be executed as root, so you have to login as root on the device or, if you are logged-in using the torizon user, prefix the following command lines with "sudo" to execute them as root.

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

To see which files got updated, `ostree diff` can be used.
```
ostree diff toradex-nightly:torizon-core-docker
M    /usr/package.manifest
M    /usr/etc/manifest.xml
...
```

Next, you queue the commit for deployment upon next boot
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

If you are building torizon image locally you may provide an ostree repo directly from your PC.  
If you have python installed, just move to the ostree_repo folder of your build directory (should be under deploy/images/$MACHINE/ostree_repo) and type:
```
python -m SimpleHTTPServer 8081
```
In this way your PC will be sharing the image you just built on port 8081. You can replace http://feeds.toradex.com/ostree/nightly/apalis-imx6/ in the above instructions with <your PC ip address>:8081 and update your device directly from your build machine.  
Please notice that this kind of operation is not secure and such a configuration should be used only for debugging purposes.  

### Building TorizonCore

To build/develop TorizonCore follow the README [here](docs/building-torizon.md) to set up your build environment.


## Known Problems/Issues

* Image Space limitation

  The full-featured image is rather large taking up most of the space on the Colibri i.MX7 raw NAND. As such it is not recommended to experiment with containers on this device since there isn't much space for containers as is. In the future, we hope to slim down the footprint. Alternatively, the Balena based image is slimmer by about ~70MB.

* Xorg video driver

  In our i.MX6 Debian containers we are using the [Armada X.org DDX driver](http://git.arm.linux.org.uk/cgit/xf86-video-armada.git/) which seems to have worked fine in our tests but, it might show stability issues.

 
* Error "No session for pid" on container startup

   The error is probably related to missing session management inside the container.

* Image not booting properly

   Make sure to clear the U-Boot environment by using `env default -a && env save`.
