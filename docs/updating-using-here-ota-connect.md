# Updating your device using HERE OTA Connect

## HERE OTA Connect Account

You can create an account for HERE OTA Connect at
https://connect.ota.here.com/. In your account settings download
`credentials.zip` which is required for provisioning.

## Prepare device for update

You will need to execute the commands as root. You can login as root or (better) use sudo command when logged in with a regular user to do it.  
First, make sure that aktualizr is stopped so it won't interfere while creating
configuration files:

```
systemctl stop aktualizr.service
```

### Import credentials and generate certificates

You can use the aktualizr-cert-provider tool to import security information from the credentials.zip file that you can download from the portal. **You should not copy this file to the device because it contains your private keys, during device setup you may access it from a USB thumbdrive or SD card. If you have to copy it, ensure that you delete the file after you executed the command below.**


```
aktualizr-cert-provider -c <path to removable media>/credentials.zip -l / -u -r
```

### Add unique device id

You should set a unique id for your device to do this you have to edit a configuration file, but first you have to copy it to a different folder to be able to modify it.

```bash
cp /usr/lib/sota/conf.d/40-hardware-id.toml /etc/sota/conf.d/
vi /etc/sota/conf.d/40-hardware-id.toml
```

You can find your device unique id inside the proc filesystem:
```bash
cat /proc/device-tree/serial-number
```

In the hardware-id file you will have to add a line with the id:
```bash
[provision]
primary_ecu_hardware_id = colibri-imx6
primary_ecu_serial = <your unique id>
```

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

Our image has a systemd service which starts aktualizr.  
To check your configuration it's better to start aktualizer interactively and check its output.  
To run the tool you can just type:

```bash
aktualizr --loglevel 1
```

On the output you will see what files are parsed and the requests made to the server.  

```
Aktualizr version 1.0+gitAUTOINC+505627bbf4 starting
Reading config: "/usr/lib/sota/conf.d/20-sota_implicit_prov_ca.toml"
Reading config: "/etc/sota/conf.d/40-hardware-id.toml"
Current directory: /sysroot/home/torizon
Use existing SQL storage: "/var/sota/sql.db"
Checking if device is provisioned...
ECUs have been successfully registered to the server
... provisioned OK
Reporting network information
No installation result to report in manifest
got SendDeviceDataComplete event
Reporting network information
No installation result to report in manifest
GET https://ffcec23d-cf13-4021-bbf8-2ef63bc4b5d7.device-gateway.ota.api.here.com:443/director/1.root.json
GET https://ffcec23d-cf13-4021-bbf8-2ef63bc4b5d7.device-gateway.ota.api.here.com:443/director/root.json
GET https://ffcec23d-cf13-4021-bbf8-2ef63bc4b5d7.device-gateway.ota.api.here.com:443/director/targets.json
No new updates found in Uptane metadata.
Reporting network information
No installation result to report in manifest
GET https://ffcec23d-cf13-4021-bbf8-2ef63bc4b5d7.device-gateway.ota.api.here.com:443/director/root.json
GET https://ffcec23d-cf13-4021-bbf8-2ef63bc4b5d7.device-gateway.ota.api.here.com:443/director/targets.json
No new updates found in Uptane metadata.
```

Above you can see the output of a successful execution.  
If you need to report issues, please include aktualizr output to help support in understanding the reasons for failure.  

Once you have tested that Aktualizr can connect to the server you may reboot your device and start deploying updates to it.

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
