# Updating docker compose file using ATS garage

## OTA Connect Account 

You can create an account here https://connect.ota.here.com/#/ and download 
```
credentials.zip
```

## Prepare device for update
### Copy credentials.zip to device
```
mount /dev/sda1 /mnt
cp /mnt/credentials.zip /var/sota/sota_provisioning_credentials.zip 
```
### Create auto provisioning configuration
This configuration is needed by Aktualizr to be able to provision a device

**If this does not match you wont be able to push updates**
```
primary_ecu_hardware_id should match HardwareID on ATS Garage. 
```
Create file 
```
vi /var/sota/20-sota_autoprov.toml 
```
and paste this content into it
```
[provision]
provision_path = "/var/sota/sota_provisioning_credentials.zip"
primary_ecu_hardware_id = "apalis-imx6"
[storage]
type = "sqlite"
[uptane]
secondary_configs_dir = "/var/sota/secondary"
```

### Add secondary system
Create directory where secondary system information will be located 
```
mkdir /var/sota/secondary
```
add information about secondary
```
vi /var/sota/sota_secondary.toml
```
Paste this into file 
```
[storage]
type = "sqlite"
sqldb_path = "/var/sota/secondary.db"
```
### Create secondary device json
Create file 
```
vi /var/sota/secondary/docker-test.json
```
Paste this into file
```
{
  "secondary_type" : "docker_compose",
  "partial_verifying" : "false",
  "ecu_hardware_id" : "docker-compose",
  "full_client_dir" : "/var/sota/storage/demo-vsec1",
  "ecu_private_key" : "sec.private",
  "ecu_public_key" : "sec.public",
  "firmware_path" : "/var/sota/storage/demo-vsec1/docker-compose.yml",
  "target_name_path" : "/var/sota/storage/demo-vsec1/target_name",
  "metadata_path" : "/var/sota/storage/demo-vsec1/metadata"
}
```

## Start aktualizr ( our image already has a service that starts it )
```
aktualizr --loglevel 0 -c /var/sota/ --secondary-configs-dir /var/sota/secondary/
```
#### You can only start aktualizr  once 
```
aktualizr --loglevel 2 -c /var/sota/ --secondary-configs-dir /var/sota/secondary/ --running-mode once  
```
#### Create a simple yml file 
```
version: '3'
services:
  redis:
    image: "redis:alpine"
    restart: always
```
Upload it to ats garage as package -> binary and you can push it out to devices

After update file is located inside 
```
vi /sysroot/home/torizon/storage/demo-vsec1/docker.yml
```

## Check if configuration is OK and provision a device
To see if it works you can use
```
aktualizr --loglevel 2 -c /var/sota/ --secondary-configs-dir /var/sota/secondary/
```
