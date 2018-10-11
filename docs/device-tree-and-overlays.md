## Oh Device Trees
Device trees are... prone to error and the cause of much grief. The source files come from a number of places, the syntax is unique to itself, building them requires a kernel tree and working build environment, and to even know if they work you need a booting system! While we can't solve all these problems, we can make it a little easier with overlays and containers.

## What are Device Trees?
You are likely already familiar with Device Trees, and I won't go into detail here. If you are not, I would reccommend a few links to get started:

https://elinux.org/Device_Tree_Reference  
https://saurabhsengarblog.wordpress.com/2015/11/28/device-tree-tutorial-arm/  
A friendly tutorial on syntax:  
https://www.raspberrypi.org/documentation/configuration/device-tree.md  

## And what about Device Tree Overlays?
Device Tree Overlays provide a way to modify the overall device tree without having to re-compile the complete device tree.
Overlays are small pieces, or fragments of a complete device tree, and can be added or removed as needed, often enabling/disabling components of hardware in the system.
It is because of this flexible nature that overlays provide an advantageous way of describing peripheral hardware, that can be added or removed from the system. It is also useful for tweaking parameters of existing hardware before commiting it to a complete device tree. Overlays are described elsewhere, but here are some links that do a good job explaining them:  
https://www.raspberrypi.org/documentation/configuration/device-tree.md  
Tutorial for BBB, but is a good example of overlays:  
https://learn.adafruit.com/introduction-to-the-beaglebone-black-device-tree/device-tree-overlays

## The Container (and whats in it)
So we built a container that has tools necessary to build, analyze, and apply both device trees and device tree overlays. This container runs on the Torizon Core Operating System, and is intended to act as a hardware configuration tool.
The bulk of the tools in this container are part of the "dtc" (device tree compiler) project and can therefore be found here: https://github.com/dgibson/dtc but are also shipped as part of the linux kernel in the `scripts/dtc` directory.

High-Level description of tools in this container are:
### dtc
The Device Tree Compiler. Used (unsurprisingly) to compile device trees and device tree overlays

### fdtget
Used for reading properties from a device tree 

### fdtput
Used for setting properties in a device tree

### fdtdump
Used to print the contents of a device tree binary in plain text.

### fdtoverlay
Used to apply an overlay, or multiple overlays to a base device tree.

### dtconf
Used to manage device-trees and device-tree overlays running on a system.

### other
This container also comes with device-tree and device-tree overlay source files. These files can be used as a base to create new device-trees or device tree overlays.


## Using the Container
```
docker run --rm -it --privileged -v /dev:/dev bclouser/device-tree:latest /bin/bash
```
This will drop your prompt into the /dt-sandbox directory which contains these folders
#### overlays/
Overlay source files developed by Toradex or the community for the module.
#### sys-overlays/
Any overlays (.dtbo) found on the boot partition of the module
#### sys-device-trees/
Any Device Trees found on the boot partition of the module and their de-compiled source

**NOTE:** dtc, fdtput, fdtget, fdtdump, dtoverlay, and dtconf should all be in your path.

### Some examples
#### Compile device tree, device tree overlay
There are actually two ways you can do this:
1.) Using the dtconf script, which has a convenient wrapper for building:
```bash
dtconf --build ./input-dt-file.dts
```
2.) Or using dtc directly:
```bash
dtc -@ -I dts -O dtb -o output-filename.dtb  input-dt-file.dts
```
**NOTE:** Both device trees (.dtb) and device tree overlays (.dtbo) are built from the same source file (.dts).
In an attempt to determine the output file type, the dtconf script will scan the .dts file for the "fragment@0" string. If this string is found it assumes file is an overlay and names the output with a .dtbo extension, otherwise, it is named with a .dtb

#### Verify device tree overlay against base device tree
This simply ensures that the device tree overlay is compatable with a specified device tree.
The device-tree parameter is optional, by default it will verify the overlay against the active device tree
```bash
dtconf --overlay verify ./some-overlay.dtbo
```
#### Set overlay to be active
```bash
dtconf --overlay active ./some-overlay.dtbo
```
#### Remove all overlay(s) from active
```bash
dtconf --overlay clear
```
#### View overall status of device trees and overlays
```bash
dtconf --status

== Active Device Tree:
imx6q-apalis-eval.dtb

== System Device Trees:
/mnt/part/custom-dt.dtb
/mnt/part/imx6q-apalis-eval.dtb
/mnt/part/imx6q-apalis-ixora-v1.1.dtb
/mnt/part/imx6q-apalis-ixora.dtb

== Active Overlays:
dpi_fusion7_timings.dtbo

== System Overlays:
/mnt/part/fdt_overlays/dpi_fusion7_timings.dtbo

== Other Overlays:
/dt-sandbox/overlays/dpi_EDT5.7_timings.dtbo
/dt-sandbox/overlays/dpi_fusion7_timings.dtbo
```
Where:

`Active Device Tree` is the device tree that is setup to be used on boot,

`System Device Trees` are the device trees found on the boot partition,

`Active Overlays` are the overlays setup to be applied to the Active Device Tree on next boot,

`System Overlays` are the overlays found on the boot partition,

`Other Overlays` are the overlays that are shipped with the container

#### Modify parameter in an overlay
Lets say we wanted to modify the resolution of our display panel to be 1280 x 720
Note: the actual resolution for the fusion 7 inch panel is 800 x 480 (0x320 x 0x1e0)
```bash
cp ./overlays/dpi_fusion7_timings.dtbo ./dpi_fusion7_custom.dtbo
fdtput ./dpi_fusion7_custom.dtbo /fragment@0/__overlay__/panel-timing hactive 1280
fdtput ./dpi_fusion7_custom.dtbo /fragment@0/__overlay__/panel-timing vactive 720
```
if you run `dtconf --print ./dpi_fusion7_custom.dtbo` you should see that the hactive and vactive have now changed to be `0x500 (1280)` and `0x2d0 (720)`
You can then verify that this overlay will apply to the active device tree by executing:
```bash
dtconf --overlay verify ./dpi_fusion7_custom.dtbo
```
And finally set it to be active by executing:
```bash
dtconf --overlay active ./dpi_fusion7_custom.dtbo
```
You would now be required to reboot for these changes to take effect

#### Known Issues
* Stack trace complaining about "possible recursive locking" gets produced, upon starting container for the first time after boot.

* Build warnings appear upon building an overlay file. This is due to the compiler assuming the file is a full device-tree instead of an overlay.
