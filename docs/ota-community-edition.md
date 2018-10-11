## Conceptual OTA
This whole system is built around OSTree, which can be conceptually thought of as "git for operating systems". 
In it's simplest form, a user on a device could perform an "ostree pull" and it would update that device with the latest and greatest from the configured remote (server). That is really all OTA is doing. This project becomes complex due to the security and update management required.

### Let's talk about aktualizr
Aktualizr runs on the device! It is a commandline program, you can quite literally run "aktualizr --help" on an lmp device right now, if you like!
It is designed and setup to run as a service with systemd. Here is the systemd unit file:
```yaml
[Unit]                                                                                            
Description=Aktualizr SOTA Client
Wants=network-online.target
After=network.target network-online.target
Requires=network-online.target

[Service]
RestartSec=180
Restart=always
EnvironmentFile=/usr/lib/sota/sota.env
EnvironmentFile=-/etc/sota/sota.env
ExecStart=/usr/bin/aktualizr $AKTUALIZR_CMDLINE_PARAMETERS

[Install]
WantedBy=multi-user.target
```
**SideNote:**
In our yocto build system, the commandline params are set for the systemd startup unit
AKTUALIZR_CMDLINE_PARAMETERS=AKTUALIZR_PARAMETERS_CONFIGFILE="--config /var/sota/sota.toml"

#### So. What does Aktualizr do?
I tend to think of it as the end device updater. It communicates with the cloud services to check for updates, and procedes with updating the device if it detects an update is necessary. Thats it!  
What makes it complicated is the levels of security/authentication it is required to provide in order to communicate with the cloud services. 
#### Useful Links/Notes
github here: https://github.com/advancedtelematic/aktualizr  
The docker images are confusingly named:  
docker image which contains the garage-push from aktualizr and garage-sign tools from ota-tuf repo (used to push ostree repos):   https://hub.docker.com/r/opensourcefoundries/aktualizr/  
whereas https://hub.docker.com/r/advancedtelematic/aktualizr/ is just a dev-environment for working on aktualizr 

## Cloud Services (Kubernetes)
Ok, so there are a whole bunch of microservices that make up ota community edition. They are all containerized and launched via Kubernetes.  
Kubernetes is configured via configmaps, and this project has two configmaps that are generated when "start.sh" is run.  

These configmaps are called "infra" and "services" and will be placed in "generated/templates"  
Infra = "infrastructure"
  
### templates
In the ota-community-edition repo: the functions which setup the microservices (contained in start.sh script) first generate the kubernetes configmap files by compiling the templates.  
These templates exist in the "templates" directory and are in go template language: https://golang.org/pkg/text/template/
these result in kubernetes configmaps output to generated/templates/

## foundries.io blog series
There is a blog series on foundries io that walks through configuring and deploying this project.
part 1: How we chose a software update system https://foundries.io/blog/2018/05/25/ota-part-1/  
part 2: What is OTA Community Edition https://foundries.io/blog/2018/06/14/ota-part-2/  
part 3: Deploying OTA Community Edition https://foundries.io/blog/2018/06/27/ota-part-3/  
part 4: Securing OTA Community Edition https://foundries.io/blog/2018/07/12/ota-part-4/  
Everything here is meant to supplement these posts and dive a little deeper in the details.  
  
## kubernetes deployments explained
To see what is running via kubernetes. Run "get deployments". A healthy deployment will looking something like:  
```shell
ota-community-edition $ ./contrib/gke/kubectl get deployments
NAME                   DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
app                    1         1         1            1           7d
campaigner             1         1         1            1           7d
campaigner-daemon      1         1         1            1           7d
device-registry        1         1         1            1           7d
director               1         1         1            1           7d
director-daemon        1         1         1            1           7d
gateway-deployment     1         1         1            1           7d
reverse-proxy          1         1         1            1           7d
tuf-keyserver          1         1         1            1           7d
tuf-keyserver-daemon   1         1         1            1           7d
tuf-reposerver         1         1         1            1           7d
web-events             1         1         1            1           7d
```

### App
Container image: advancedtelematic/ota-plus-web  
* The web UI frontend and backend router.  
* It is tracked in github (confusingly) as: https://github.com/advancedtelematic/ota-plus-server

### Campaigner
Container Image: advancedtelematic/campaigner  
* Creates, tracks, and schedules updates. Keeps statistics, tracks devices. Communicates with device registry and director.  
* Fetches batches of devices from the device registry and signals the director if updates are needed.  
* https://docs.atsgarage.com/usage/campaigns.html

### Device-Registry
Container Image: advancedtelematic/device-registry
* Just a database. MariaDB (fork of mysql) Stores device info. Think: "lshw"  

### Director (UPTANE)
Container Image: advancedtelematic/director  
* The implementation of UPTANE. Uses online keys.  
* This is in charge of telling each device what ostree ref it should be running. It communicates with the device registry, and aktualizr talks to it.  
* On a device, the files /var/sota/meta-data/director/ tell the device which image-set for aktualizr to install.  

### Gateway Deployment
Container Image: nginx  
* The Gateway and OTA+ Web are responsible for securely proxying requests from devices and the browser to: the Device Registry, Director, Repo Server, and TreeHub.  
  
### Reverse Proxy
Container Image: nginx   
* Routes traffic from garage tools to Repo Server and Treehub.  
* The garage-push and garage-sign tools used by OE builds require access to the TreeHub and Repo Server respectively. These have no built-in authentication, so a custom proxy must be created if you want to host these securely on the Internet.*

### TUF
Creates targets.json which lists **all** good ostree images that could be installed on a device. It is the job of the director to dictate which image for aktualizr to install on the device.
##### Tuf-Keyserver
Container Image: advancedtelematic/tuf-keyserver  
##### Tuf-reposerver
Container Image: advancedtelematic/tuf-reposerver  

### web-events
Container Image: advancedtelematic/web-events  
* Publish events via websockets. I am guessing this just updates any listening web clients.

### Treehub
Container Image: advancedtelematic/treehub  
* Holds the ostree repo, http API.
* This will likely be swapped out for a different solution.

### infra (extras)
The templates/infra configures these other containers.
##### kafka (apache kafka), and ZooKeeper (apache zookeeper)
* Kafka requires zookeeper, Kafka is used as a message queue. I am pretty sure these are required by-products of the scala architecture that is used throughout this project
* https://www.confluent.io/
* https://kafka.apache.org/

### The Daemons
Still not 100% clear. I believe they are used to offload things so the web ui isn't blocking.

## OTA Overall Flow
1. A user uses "garage-push" to upload a new ostree image to treehub. "garage-sign" updates the targets.json meta-file to contain all the good ostree images which now includes this newly created ostree image"
2. Using the web-ui a user, indicates that an update should be applied to a device or group of devices. This spins the "campaigner" which tells the director which devices it should push new metadata. This new metadata specifies this new ostree image as the one that should be currently installed.
4. Aktualizer pulls the updated metadata down from the director
5. Aktualizer (running on the device) notices that the device is not running the same ostree version as specified in /var/sota/metadata/director/ and procedes to update the device by means of an ostree pull.
6. Manual reboot of the device is required to complete the update.


## Security 
### High Level Concept
https://docs.atsgarage.com/concepts/ats-garage-security-with-uptane.html  

*The most important concept in Uptane is that there are two sets of metadata, from separate sources, that must agree with each other and have valid cryptographic signatures.*

*The first comes from the TUF Repository The TUF Repository contains metadata for update packages that are valid install targets, and its metadata is signed by a chain of trust with offline keys.*

*The second comes from the Director, which controls what updates (selected from the valid install targets) should actually be installed on devices. The Director uses online keys, and is part of the ATS Garage service.*


### Credentials and Certs (NEEDS WORK)
The server_ca.pem that is generated is mapped into the aktualizr config file as tls_cacert_path

#### credentials.zip
* This is usually downloaded from the web front-end once everything is up and running. 
* https://github.com/advancedtelematic/aktualizr/blob/master/docs/credentials.adoc  
* It is only used by aktualizr during autoprovisioning. When doing implicit provisioning, one would only need it for garage-push because the aktualizr config file is used to specify all the keys manually eliminating the need for credentials.zip on the device.  
* https://docs.atsgarage.com/concepts/provisioning-methods-and-credentialszip.html

#### Rotating Keys
* The keys used for the repo-server are offline keys. But can be rotated by the garage-sign tool.
* https://docs.atsgarage.com/prod/rotating-signing-keys.html

## Repo-Server (TUF)
* https://theupdateframework.github.io/metadata.html
* Provides a signed targets/root/etc.json file that follows TUF guidelines.
* This tells aktualizr what valid OSTree refs it can use.
### So there is a set of garage tools. most notably the garage-sign tool
`garage-push`, `garage-deploy`, `garage-sign`, and `garage-check`  
* https://github.com/advancedtelematic/aktualizr/tree/master/src/sota_tools
There is a .deb file available:    
 https://github.com/advancedtelematic/aktualizr/releases/download/2018.7/garage_deploy.deb
* `garage-sign` can update the keys used for TUF. These are offline keys and should thusly be kept quite secret... HSM level secret. The link below talks about these keys, and how to update them.
* https://docs.atsgarage.com/prod/rotating-signing-keys.html



## Director (UPTANE)
### The living document for UPTANE
https://docs.google.com/document/d/1pBK--40BCg_ofww4GES0weYFB6tZRedAjUy6PJ4Rgzk/edit#  
This tells the device what item in the targets.json it should be using.  

## Notes on foundries ota blog series
### DNS
(kubctl get svc reverse-proxy) tuf-reposerver.<domain>  
(kubectl get svc reverse-proxy) treehub.<domain>  
(kubectl get svc reverse-proxy) app.<domain>  
 
#### General requests
server_name = ota-ce.<domain>  
(kubectl get svc gateway-service) <server_name!!!>  

#### My additions to /etc/hosts file
```shell
35.233.187.44 tuf-reposerver.example.com
35.233.187.44 treehub.example.com
35.233.187.44 app.example.com

35.227.159.239 ota-ce.example.com
```

#### You need to copy all the keys to the device:
 `generated/<SERVER_NAME>/server_ca.pem` ------>  `/var/sota/root.crt`  
 `generated/<SERVER_NAME>/devices/<DEVICE>/client.pem` ------> `/var/sota/client.pem`    
 `generated/<SERVER_NAME>/devices/<DEVICE>/pkey.pem` ------> `/var/sota/pkey.pem`   

#### Since we are doing implicit provisioning, We have to make your own sota.toml which will be placed in /var/sota/:
```toml
[gateway]
http = true
socket = false

[network]
socket_commands_path = "/tmp/sota-commands.socket"
socket_events_path = "/tmp/sota-events.socket"
socket_events = "DownloadComplete, DownloadFailed"

[p11]
module = ""
pass = ""
uptane_key_id = ""
tls_ca_id = ""
tls_pkey_id = ""
tls_clientcert_id = ""

[tls]
server = "https://ota-ce.example.com:8443"
ca_source = "file"
pkey_source = "file"
cert_source = "file"

[provision]
server = "https://ota-ce.example.com:8443"
p12_password = ""
expiry_days = "36000"
provision_path = ""

[uptane]
polling = true
polling_sec = 10
device_id = ""
primary_ecu_serial = ""
# NOTE - this might need to change depending on your CPU
primary_ecu_hardware_id = "intel-corei7-64"
director_server = "https://ota-ce.example.com:8443/director"
repo_server = "https://ota-ce.example.com:8443/repo"
key_source = "file"

[pacman]
type = "ostree"
os = ""
sysroot = ""
ostree_server = "https://ota-ce.example.com:8443/treehub"
packages_file = "/usr/package.manifest"

[storage]
type = "filesystem"
path = "/var/sota/"
uptane_metadata_path = "metadata"
uptane_private_key_path = "ecukey.der"
uptane_public_key_path = "ecukey.pub"
tls_cacert_path = "root.crt"
tls_pkey_path = "pkey.pem"
tls_clientcert_path = "client.pem"

[import]
uptane_private_key_path = ""
uptane_public_key_path = ""
tls_cacert_path = "/var/sota/root.crt"
tls_pkey_path = ""
tls_clientcert_path = ""
```


### When things are up and running (server side), output should be similar.
```shell
ota-community-edition $ ./contrib/gke/kubectl get services
NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)                                      AGE
app                    ClusterIP      10.31.243.159   <none>           80/TCP                                       1d
campaigner             ClusterIP      10.31.247.162   <none>           80/TCP                                       1d
device-registry        ClusterIP      10.31.250.69    <none>           80/TCP                                       1d
director               ClusterIP      10.31.254.121   <none>           80/TCP                                       1d
gateway-service        LoadBalancer   10.31.247.43    35.233.204.229   80:30157/TCP,8443:30443/TCP,8000:32105/TCP   1d
kafka                  ClusterIP      10.31.240.85    <none>           9092/TCP                                     1d
kubernetes             ClusterIP      10.31.240.1     <none>           443/TCP                                      1d
mysql                  ClusterIP      10.31.249.155   <none>           3306/TCP                                     1d
reverse-proxy          LoadBalancer   10.31.251.186   35.185.252.46    80:32368/TCP,8443:30212/TCP                  1d
treehub                ClusterIP      10.31.240.30    <none>           80/TCP                                       1d
tuf-keyserver          ClusterIP      10.31.252.98    <none>           80/TCP                                       1d
tuf-keyserver-daemon   ClusterIP      10.31.249.79    <none>           80/TCP                                       1d
tuf-reposerver         ClusterIP      10.31.248.96    <none>           80/TCP                                       1d
web-events             ClusterIP      10.31.247.79    <none>           80/TCP                                       1d
zookeeper              ClusterIP      10.31.248.222   <none>           2181/TCP,2888/TCP,3888/TCP                   1d


ota-community-edition $ ./contrib/gke/kubectl  get deployments
NAME                   DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
app                    1         1         1            1           1d
campaigner             1         1         1            1           1d
campaigner-daemon      1         1         1            1           1d
device-registry        1         1         1            1           1d
director               1         1         1            1           1d
director-daemon        1         1         1            1           1d
gateway-deployment     1         1         1            1           1d
reverse-proxy          1         1         1            1           1d
tuf-keyserver          1         1         1            1           1d
tuf-keyserver-daemon   1         1         1            1           1d
tuf-reposerver         1         1         1            1           1d
web-events             1         1         1            1           1d

```

### Debugging
waiting for kafka is normal and can take a while... more than 30 minutes, id get concerned
#### To Check the health of a specific node
`EXTRA_ARGS="-it" ./contrib/gke/gcloud shell`
inside that shell do: 
`kubectl proxy &`
and then run a curl command to hit the "health" api item of the node you care about (in this example "director"):
`curl http://localhost:8001/api/v1/namespaces/default/services/director/proxy/health`

## OSTree Notes
So on the device, you can run ostree commands to see what's up.
/sysroot/ostree holds all the goodies
```shell
root@colibri-imx7:/sysroot/ostree# ostree --repo=repo refs
ostree/0/1/0
ostree/0/1/1
```
`ostree admin status` tells you what ostree ref is currently configured.
```shell
* lmp eb6eff700318e57761bd567f806e64c923fc10ee57493043259c11f4b832f354.0
    origin refspec: eb6eff700318e57761bd567f806e64c923fc10ee57493043259c11f4b832f354
  lmp b4c0a18af1a99f3f62747a6097cf9cd146b0acdfba089bc3cda89543697c8f3b.0 (rollback)
    origin refspec: b4c0a18af1a99f3f62747a6097cf9cd146b0acdfba089bc3cda89543697c8f3b
```

More good ostree info here: https://docs.atsgarage.com/tips/ostree-usage.html
