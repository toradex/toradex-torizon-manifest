TordyOS Manifest
============================

Toradex TordyOS manifest, based on Linux microPlatform from foundries.io.

This directory contains a Repo manifest and setup scripts for the
TordyOS build system. If you want to modify, extend or port TordyOS
to a new hardware platform, this is the manifest repository to
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

Run `repo init` to bring down the latest stable version of Repo. You must
specify a URL for the manifest, which specifies the various repositories that
will be placed within your working directory.

To check out the latest TordyOS release:

```
repo init -u http://gitlab.toradex.int/tordyos/lmp-manifest.git -b master-toradex
```

When prompted, configure Repo with your real name and email address.

A successful initialization will end with a message stating that Repo
is initialized in your working directory. Your client directory should
now contain a .repo directory where files such as the manifest will be
kept.

To pull down the metadata sources to your working directory from the
repositories as specified in the Linux microPlatform manifest, run:

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

Supported **MACHINE** targets (officially tested by Toradex):
* Colibri i.MX7 (raw NAND & eMMC)
* Colibri i.MX6
* Apalis i.MX6

Supported image targets:
* lmp-gateway-image
* lmp-mini-image

The default distribution (DISTRO) variable is automatically set to `tordy`,
which is provided by the `meta-toradex-tordy` layer.

Setup the work environment by using the `setup-environment` script:

```
[MACHINE=<MACHINE>] source setup-environment [BUILDDIR]
```

If **MACHINE** is not provided, the script will list all possible machines and
force one to be selected.

To build the TordyOS gateway image:

```
bitbake lmp-gateway-image
```
