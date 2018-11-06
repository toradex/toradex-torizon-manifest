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

### dtconf
Used to manage device-trees and device-tree overlays running on a system.

### other
This container also comes with device-tree and device-tree overlay source files. These files can be used as a base to create new device-trees or device tree overlays.

Default overlays are located inside
```bash
/usr/src/dts/overlays 
```

## Using the Container
```bash
docker pull torizon/torizon-tools-container
docker run --rm --privileged --tmpfs /run/lock -it -v /dev:/dev torizon/torizon-tools-container /bin/bash 
```
### Some examples
#### Compile device tree, device tree overlay
There are actually two ways you can do this:
Using the dtconf script, which has a convenient wrapper for building:
```bash
dtconf -a /usr/src/dts/overlays/display_EDT7_parallel_res_touch.dts
```
iMX7 modules also need extra parameter specifying current  device tree
```bash
dtconf -a /usr/src/dts/overlays/display_EDT7_parallel_res_touch.dts -c imx7d-colibri-emmc-eval-v3.dtb
```

**NOTE:** Both device trees (.dtb) and device tree overlays (.dtbo) are built from the same source file (.dts).
In an attempt to determine the output file type, the dtconf script will scan the .dts file for the "fragment@0" string. If this string is found it assumes file is an overlay and names the output with a .dtbo extension, otherwise, it is named with a .dtb.

#### Applying multiple overlays
This allows for configuration of multiple different overlays. In example below it setups the display and configures touch controller.
```bash
dtconf -a /usr/src/dts/overlays/display_7_parallel_cap_touch.dts /usr/src/dts/overlays/touch_cap_colibri_imx6_aster.dts
```
#### Verify device tree overlay against base device tree
This simply ensures that the device tree overlay is compatable with a specified device tree.
The device-tree parameter is optional, by default it will verify the overlay against the active device tree:
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

`Active Device Tree` is the device tree that is setup to be used on boot.

`System Device Trees` are the device trees found on the boot partition.

`Active Overlays` are the overlays setup to be applied to the Active Device Tree on next boot.

`System Overlays` are the overlays found on the boot partition.

`Other Overlays` are the overlays that are shipped with the container.

#### Modify parameter in an overlay
You can modfiy any of the overlays we provide and then verify them

First you need to build overlay
```bash
dtconf -b modified_overlay.dts
```
You can then verify that this overlay will apply to the active device tree by executing:
```bash
dtconf -o verify modified_overlay.dtbo
```
And finally set it to be active by executing:
```bash
dtconf -o active modified_overlay.dtbo
```
You would now be required to reboot for these changes to take effect.

#### Known Issues
* Build warnings appear upon building an overlay file. This is due to the compiler assuming the file is a full device-tree instead of an overlay.
