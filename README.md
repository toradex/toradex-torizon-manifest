default.xml
=================

Open Source Foundries Linux microPlatform manifest.

This directory contains a Repo manifest and setup scripts for the
Linux microPlatform build system. If you want to (re)build packages or
images for the Linux microPlatform, this is the manifest repository to
use.

The build system uses various components from the Yocto
Project, most importantly the OpenEmbedded build system, the bitbake
task executor and various application and BSP layers.

To configure the scripts and download the build metadata, do:

```
mkdir ~/bin
PATH=~/bin:$PATH

curl http://commondatastorage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
```

Run repo init to bring down the latest version of Repo with all its
most recent bug fixes. You must specify a URL for the manifest, which
specifies where the various repositories included in the Android
source will be placed within your working directory. To check out the
latest branch:

```
repo init -u https://git.foundries.io/YOUR_TREE/manifests.git
```

Where YOUR_TREE in the URL points to a version of this repository you
have access to.

When prompted, configure Repo with your real name and email address.

A successful initialization will end with a message stating that Repo
is initialized in your working directory. Your client directory should
now contain a .repo directory where files such as the manifest will be
kept.

To pull down the metadata sources to your working directory from the
repositories as specified in the Linux microPlatform manifest, run

```
repo sync
```

When downloading from behind a proxy (which is common in some
corporate environments), it might be necessary to explicitly specify
the proxy that is then used by repo:

```
export HTTP_PROXY=http://<proxy_user_id>:<proxy_password>@<proxy_server>:<proxy_port>
export HTTPS_PROXY=http://<proxy_user_id>:<proxy_password>@<proxy_server>:<proxy_port>
```

More rarely, Linux clients experience connectivity issues, getting
stuck in the middle of downloads (typically during "Receiving
objects"). It has been reported that tweaking the settings of the
TCP/IP stack and using non-parallel commands can improve the
situation. You need root access to modify the TCP setting:

```
sudo sysctl -w net.ipv4.tcp_window_scaling=0
repo sync -j1
```

Setup Environment
-----------------

MACHINE values can be:
* beaglebone
* cl-som-imx7
* cubox-i
* dragonboard-410c
* dragonboard-820c
* hikey
* ls1043ardb
* raspberrypi3

DISTRO values can be:
* rpb

```
. setup-environment
MACHINE=<machine> DISTRO=<distro> bitbake IMAGE_NAME
```

e.g. MACHINE=hikey DISTRO=rpb bitbake rpb-ltd-gateway-image

Maintainers
-------------------------

* Ricardo Salveti <mailto:ricardo@opensourcefoundries.com>
