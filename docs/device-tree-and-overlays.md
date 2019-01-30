## And what about Device Tree Overlays?
Device Tree Overlays provide a way to modify the overall device tree without having to re-compile the complete device tree.
Overlays are small pieces, or fragments of a complete device tree, and can be added or removed as needed, often enabling/disabling components of hardware in the system.
It is because of this flexible nature that overlays provide an advantageous way of describing peripheral hardware, that can be added or removed from the system. It is also useful for tweaking parameters of existing hardware before commiting it to a complete device tree. Overlays are described elsewhere, but here are some links that do a good job explaining them:  

- [Device Trees, overlays, and parameters](https://www.raspberrypi.org/documentation/configuration/device-tree.md)  
- [Tutorial for BBB, but is a good example of overlays](https://learn.adafruit.com/introduction-to-the-beaglebone-black-device-tree/device-tree-overlays)  

## The Container (and whats in it)

So we built a container that has tools necessary to build, analyze, and apply both device trees and device tree overlays. This container runs on the Torizon Core Operating System, and is intended to act as a hardware configuration tool.
The bulk of the tools in this container are part of the "dtc" (device tree compiler) project and can therefore be found [here](https://github.com/dgibson/dtc), but are also shipped as part of the linux kernel in the `scripts/dtc` directory.  
Overlays in human-readable format (dts files) must be compiled to binary format (dtb for complete device-trees, dtbo for overlay) to be parsed by the kernel.  

High-Level description of tools in this container are:

### dtconf

Used to manage device-trees and device-tree overlays running on a system.

### other

This container also comes with device-tree and device-tree overlay source files. These files can be used as a base to create new device-trees or device tree overlays.

Default overlays are located inside

```code
/usr/src/dts/overlays
```

## Using the Container

```bash
docker pull torizon/torizon-core-tools-container
docker run --rm --privileged --tmpfs /run/lock -it -v /dev:/dev -v /boot:/boot torizon/torizon-core-tools-container /bin/bash
```

### dtconf Command Line Options

```code
Usage: dtconf < command > [arguments]
commands:
        -h, --help
        -b, --build < dts file(s) > [ dtb/dtbo file ]
        -s, --status
        -v, --validate < dtb file(s) > -c [ active dtb name ]
        -e, --enable <dtb name/all>
        -d, --disable <dtb name/all>
        -a, --activate < dts file(s) > -c [ active dtb name]
        -p, --print <dtb file(s)>
```

- The **-s/--status** option prints out a list of currently active overlays and of the device trees that are available on the device.
- The **-b/--build** option compiles a dts code file into a device-tree or device-tree overlay file.
- The **-v/--validate** options checks that an overlay file is compatible with a device tree. Depending on the Torizon image and SOC you may have multiple valid device trees on your boot partition, in this case you should specify the one that is currently used with the "-c" additional parameter.
- The **-e/--enable** options copies a binary device tree overlay to the boot partition and adds it to the list of overlays that are activated at boot.
- The **-a/--activate** options builds a source dts, validates it and enables it in a single step. It's equivalent to run -b -v and -e commands in sequence.
- The **-d/--disable** options can be used to remove one overlay from the list of those that are applied at boot. If **all** is specified, all overlays will be removed.
- The **-p/--print** option translate a binary device-tree file back into human readable format, it can be used to debug issues or document the configuration changes performed by active overlays  

Overlays are applied at boot, so the options that affect active overlays configuration (-a,-e and -d) will require a reboot to apply the required changes.

### Some examples

#### Compile device tree or device tree overlay

Build command can be used to convert a dts into a binary device tree file.

```bash
dtconf -b /usr/src/dts/overlays/display_EDT7_parallel_res_touch.dts
```

**NOTE:** Both device trees (.dtb) and device tree overlays (.dtbo) are built from the same source file (.dts).
In an attempt to determine the output file type, the dtconf script will scan the .dts file for the "fragment@0" string. If this string is found it assumes file is an overlay and names the output with a .dtbo extension, otherwise, it is named with a .dtb.

#### Enable overlays

You can enable an overlay using a binary dtbo file:

```bash
dtconf -e display_7_parallel_cap_touch.dts touch_cap_colibri_imx6_aster.dts.dtbo
```

or directly using dts file, in this case the overlay is first compiled to binary format, then validated and then enabled.
enabled.

```bash
dtconf -a display_7_parallel_cap_touch.dts /usr/src/dts/overlays/touch_cap_colibri_imx6_aster.dts
```

On some modules where multiple device-trees are provided (ex: colibri-imx7, apalis-imx6) you'll have to provide an additional parameter, to select the target device tree.

```bash
dtconf -a display_7_parallel_cap_touch.dts /usr/src/dts/overlays/touch_cap_colibri_imx6_aster.dts -c devicetree-imx7d-colibri-emmc-eval-v3.dtb
```

#### Verify device tree overlay against base device tree

This simply ensures that the device tree overlay is compatable with a specified device tree.
The device-tree parameter is optional, by default it will verify the overlay against the active device tree:

```bash
dtconf -v some-overlay.dtbo
```

#### Deactivate an overlay

```bash
dtconf -d display_7_parallel_cap_touch.dts touch_cap_colibri_imx6_aster.dts.dtbo
```

Please notice that you should not specify a full path for the overlay because active overlays are stored in the boot partition.

#### Remove all active overlays

```bash
dtconf -d all
```

#### View overall status of device trees and overlays

```bash
dtconf -s

Currently active overlays:
display_EDT7_parallel_res_touch.dts.dtbo
Available device trees:
devicetree-imx7s-colibri-eval-v3.dtb
devicetree-imx7d-colibri-emmc-eval-v3.dtb
devicetree-imx7d-colibri-eval-v3.dtb
```

#### Modify parameter in an overlay

You can modfiy any of the overlays we provide and then verify them

First you need to build overlay

```bash
dtconf -b modified_overlay.dts
```

You can then verify that this overlay will apply to the active device tree by executing:
```bash
dtconf -v modified_overlay.dtbo
```

And finally set it to be active by executing:

```bash
dtconf -e modified_overlay.dtbo
```

You would now be required to reboot for these changes to take effect.

#### Known Issues

* Build warnings appear upon building an overlay file. This is due to the compiler assuming the file is a full device-tree instead of an overlay.
