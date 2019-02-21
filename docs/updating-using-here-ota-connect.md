# Updating your device using HERE OTA Connect

## HERE OTA Connect Account

You can create an account for HERE OTA Connect at
https://connect.ota.here.com/. In your account settings download
`credentials.zip` which is required for provisioning.

## Prepare device for update

First, make sure that aktualizr is stopped so it won't interfere while creating
configuration files:

```
systemctl stop aktualizr.service
```

### Copy credentials.zip to device

Copy the credentials.zip onto the device, e.g. using scp:

```
host $ scp credentials.zip torizon@colibri-imx7-02965221.local:sota_provisioning_credentials.zip
```

Make sure to store it on /var/sota/
```
root@colibri-imx7-02965221.local # mv /home/torizon/sota_provisioning_credentials.zip /var/sota/
```

**If this does not match you wont be able to push updates**

### Create auto provisioning configuration

The provision configuration is needed by Aktualizr to be able to provision a device.

Create an aktualizr configuration file for provisioning:
```
vi /etc/sota/conf.d/20-sota_autoprov.toml
```

And paste this content into it:
```
[provision]
provision_path = "/var/sota/sota_provisioning_credentials.zip"
primary_ecu_hardware_id = "apalis-imx6"
[storage]
type = "sqlite"
[uptane]
secondary_configs_dir = "/etc/sota/secondary/"
```

The `primary_ecu_hardware_id` is the string which will appear as "Hardware id"
on HERE OTA Connect.


### Add secondary system (optional)

If you plan to also push Docker Compose files to the device, you can add a
Docker compose specific secondary. First create directory where secondary system
information will be located:

```
mkdir /etc/sota/secondary
```

Create the secondary JSON file:

```
vi /etc/sota/secondary/docker-test.json
```

Paste this into the file:
```
{
  "secondary_type" : "docker_compose",
  "partial_verifying" : "false",
  "ecu_hardware_id" : "docker-compose",
  "full_client_dir" : "/var/sota/storage/docker-compose",
  "ecu_private_key" : "sec.private",
  "ecu_public_key" : "sec.public",
  "firmware_path" : "/var/sota/storage/docker-compose/docker-compose.yml",
  "target_name_path" : "/var/sota/storage/docker-compose/target_name",
  "metadata_path" : "/var/sota/storage/docker-compose/metadata"
}
```

### Enable automatic reboot

After update aktualizr creates a file in `/run/aktualizr-session/need_reboot`.
If you want the system to automatically reboot after an successful update,
TorizonCore provides a systemd path unit configuration. Enable the path unit
path like this:

```
systemctl enable ostree-pending-reboot.path
systemctl start ostree-pending-reboot.path
```

## Start aktualizr

Our image has a systemd service which starts aktualizr. If you stopped the
service, start it agian using `systemctl start aktualizr.service` or reboot
the device. Check aktualizr's output using `systemd status aktualizr.service`.
If provisioning succeeds you should see something like this in the output:

```
aktualizr[797]: Aktualizr version 1.0+gitAUTOINC+1cad6d1028 starting
aktualizr[797]: Reading config: "/etc/sota/conf.d/20-sota_autoprov.toml"
aktualizr[797]: Reading config: "/usr/lib/sota/conf.d/40-hardware-id.toml"
aktualizr[797]: Parsing secondary config: "/etc/sota/secondary/docker-test.json"
aktualizr[797]: Bootstrap empty SQL storage
aktualizr[797]: Could not find primary ecu serial, defaulting to empty serial: no more rows available
aktualizr[797]: Provisioned successfully on Device Gateway
aktualizr[797]: ECUs have been successfully registered to the server
aktualizr[797]: created: /var/sota/storage
aktualizr[797]: created: /var/sota/storage/demo-vsec1
aktualizr[797]: created: /var/sota/storage/demo-vsec1/metadata
aktualizr[797]: got SendDeviceDataComplete event
```

### Troubleshooting

To see in more detail what aktualizr is doing, you can stop the systemd service
and start aktualizr manually, e.g. with an increased loglevel for debugging:

```
systemctl stop aktualizr
aktualizr --loglevel 1
```

To provision the device again, make sure to stop aktualizr, remove the device
and the secondary storage entirly and start aktualizr again:

```
rm /var/sota/sql.db
rm -rf /var/sota/storage/
```

#### Common issues

If you see the following message:

```
response http code: 400
response: "An error occurred: Missing entity: Ecu"
could not put manifest
```

Make sure to properly delete the storage of the secondary (see above).

## Deploy a Docker Compose yml file

```
version: '3'
services:
  redis:
    image: "redis:alpine"
    restart: always
```
Upload it to OTA HERE Connect as Packages -> Add Package (top left corner),
select "docker-compose" under "Hardware ids".

After update file is located inside:
```
cat /var/sota/storage/docker-compose/docker-compose.yml
```

Aktualizr will call `docker-compose` automatically, hence the new containers
should get started shortly after the update.
