# TorizonCore Build Guide


This repository contains a Repo manifest and setup scripts for the
TorizonCore build system. If you want to modify, extend or port TorizonCore
to a new hardware platform, this is the manifest repository to
use.

The build system uses various components from the Yocto
Project, most importantly the OpenEmbedded build system, the bitbake
task executor and various application and BSP layers.

Toradex TorizonCore is based on Linux microPlatform from foundries.io
and therefore requires the meta-lmp layer.

## Download Metadata

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

To check out the latest TorizonCore release:

```
repo init -u https://github.com/toradex/toradex-torizon-manifest -b master
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

## Setup Environment

Supported **MACHINE** targets (officially tested by Toradex):
* colibri-imx7 - Colibri i.MX7 (raw NAND & eMMC)
* colibri-imx6 - Colibri i.MX6
* colibri-imx6ull - Colibri i.MX6ULL
* apalis-imx6 - Apalis i.MX6

Supported image targets:
* torizon-core-docker
* torizon-core-balena
* torizon-core-lite

The default distribution (DISTRO) variable is automatically set to `torizon`,
which is provided by the `meta-toradex-torizon` layer.

Setup the work environment by using the `setup-environment` script:

```
[MACHINE=<MACHINE>] source setup-environment [BUILDDIR]
```

If **MACHINE** is not provided, the script will list all possible machines and
force one to be selected.

## Start Building

To build the TorizonCore image:

The above setup script should properly prepare the enviroment with correct defaults. 
Additonally you'll want to modify the local.conf file by adding `ACCEPT_FSL_EULA="1"`.

```
bitbake torizon-core-docker
```

## Building Torizon Tools Container

To build the Torizon-Tools-Container image:

The above setup script should properly prepare the enviroment with correct defaults.

You just need to change distro inside conf/auto.conf to  `DISTRO ?= "torizon-container"`.

Additonally you'll want to modify the local.conf file by adding `ACCEPT_FSL_EULA="1"`.

```
bitbake torizon-tools-container
```

## HERE OTA Connect

Prerequisites for using this is that you have credentials file provided by HERE OTA Connect ( You can find some more documentation here https://docs.atsgarage.com/index.html)
```
credentials.zip 
```

### Pushing images to HERE OTA Connect

To push OSTree automatically to HERE OTA Connect after every build edit local.conf by adding: 

```
SOTA_PACKED_CREDENTIALS = "<PATH TO CREDENTIALS>/credentials.zip"
```

### Registering a device

Copy credentials.zip inside 
```
/etc/sota/conf.d
```
And create a file called
 ```
/etc/sota/conf.d/sota.toml
```
Add below text to sota.toml
```
[provision]
provision_path = "/etc/sota/conf.d/credentials.zip" 
[storage]   
type = "sqlite" 
```

Aktualizr should automatically detect changes and register this device to your HERE OTA Connect.

You can also force Aktualizr to restart and register device.
```
systemctl restart aktualizr 
```
The complete and automated OTA update system is still in the works.
