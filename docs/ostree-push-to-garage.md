# Push to Garage

This tool can be used to add files to a torizon base root file system and upload a package to HERE OTA Connect! that can then be deployed to devices.  
The tool, running on your development machine, will download a torizon root filesystem via ostree and merge it with the contents of a local directory.  
Files in the local directory will be added to the root filesystem of Torizon.  
For example, if you have a folder with this structure:

```
fs
├── dummydir1
│   └── dummydir2
│       └── dummyfile2
└── dummyfile1

2 directories, 2 files
```

and pass it to the tool as root folder, and then deploy the update to a device you will have dummydir1 and dummyfile1 under root:

```bash
colibri-imx6-04983097:~$ ls / -la
total 36
drwxr-xr-x   13 root     root          4096 Feb 22 14:38 .
drwxr-xr-x   13 root     root          4096 Feb 22 14:38 ..
lrwxrwxrwx    1 root     root             7 Feb 22 14:37 bin -> usr/bin
drwxr-xr-x    4 root     root          4096 Feb 22 14:38 boot
drwxr-xr-x   13 root     root         14440 Feb 22 14:48 dev
drwxrwxr-x    3 root     root          4096 Jan  1  1970 dummydir1
-rw-rw-r--    2 root     root             7 Jan  1  1970 dummyfile1
drwxr-xr-x   32 root     root          4096 Feb 22 14:48 etc
lrwxrwxrwx    1 root     root            17 Feb 22 14:37 home -> var/rootdirs/home
lrwxrwxrwx    1 root     root             7 Feb 22 14:37 lib -> usr/lib
lrwxrwxrwx    1 root     root            18 Feb 22 14:37 media -> var/rootdirs/media
lrwxrwxrwx    1 root     root            16 Feb 22 14:37 mnt -> var/rootdirs/mnt
lrwxrwxrwx    1 root     root            14 Feb 22 14:37 ostree -> sysroot/ostree
dr-xr-xr-x   96 root     root             0 Jan  1  1970 proc
drwxrwxrwt   14 root     root           400 Feb 22 14:51 run
lrwxrwxrwx    1 root     root             8 Feb 22 14:37 sbin -> usr/sbin
dr-xr-xr-x   12 root     root             0 Feb 22 14:48 sys
drwxr-xr-x   12 root     root          4096 Feb 22 14:38 sysroot
drwxrwxrwt   10 root     root           200 Feb 22 14:49 tmp
drwxr-xr-x   13 root     root          4096 Jan  1  1970 usr
drwxr-xr-x    8 root     root          4096 Feb 22 14:48 var
colibri-imx6-04983097:~$
```

The tools needs to know module type, the source ostree repository, the branch you want to use for your image and accepts a folder with the additional contents and credentials for HERE OTA Connect! packaged as a zip file (this is the format those credentials are usually provided from the web user interface).  

The tool is distributed as a docker container so you'll have to run it using docker.  
Starting the container with no additional arguments on your development PC will show a help message:

```
Usage: pushtogarage [options] remote branch folder credentials
parameters:
        module: module type, can be one of the following:
                colibri-imx6
                apalis-imx6
                colibri-imx7/emmc
                colibri-imx7/rawnand
                colibri-imx6ull
        repo: ostree remote (ex: http://feeds.toradex.com/ostree/nightly/colibri-imx7/)
        branch: branch that should be taken from remote (ex: torizon/torizon-core-docker)
        folder: folder containing files to be added to image
        credentials: credentials file (json or zip)
options:
        -v, --verbose: generate more verbose output about performed operations
```

You can pass arguments to the docker command line but, since the tool need to access local filesystem to collect the files that should be added to the image and to generate the output image, you'll have to provide mountpoints using -v option of docker.

```bash
~$ docker run -it --rm -v $(pwd)/fs:/builder/fs -v $(
pwd)/credentials.zip:/builder/credentials.zip torizon/ostree-push-to-garage:latest pushtogarage -v colibri-imx6 http://fee
ds.toradex.com/ostree/nightly/colibri-imx6/ torizon/torizon-core-docker /builder/fs /builder/credentials.zip
```
It will require a few minutes to download the ostree repository and upload the package, execution time will depend mostly on your internet connection speed.  

```
Merging changes...
Pulling remote http://feeds.toradex.com/ostree/nightly/colibri-imx6/ torizon/torizon-core-docker
Pull: 122050 bytes transferred.
[...]
Pull: 242984365 bytes transferred.
Pull: 242988332 bytes transferred.
Committing changes from /builder/fs to changes
Transaction committed. 14 bytes 2 objects written.
Merging remote torizon/torizon-core-docker - commit 89c0d733a24282915c9f9b8df08e6847879429f84857e7040087e98941677fa8...
Checking out tree to merge...
Merging local changes - commit 0684d4b0ee3c4b638814ae77b459aba90fab7afaa6196fc5ea1b8f45bec0978c...
Merging into merge...
Committing changes from merge to merged
Transaction committed. 14 bytes 2 objects written.
Commit ad7f57ec73e1dd863b7d822f4d4e0949ed643315508aa297f8b14ed003aee7d5 has been generated.
Pushing new version.
Using oauth2 authentication token
Already present: c2/66d420d9b4470615cdcc7da15abf9a0cb11631f35fed569a9848cb0bf5f9c2.dirtree
Already present: 44/6a0ef11b7cc167f3b603e585c7eeeeb675faa412d5ec73f62988eb0b6c5488.dirmeta
Uploading ad/7f57ec73e1dd863b7d822f4d4e0949ed643315508aa297f8b14ed003aee7d5.commit
Upload to Treehub complete after 4 requests
Shutting down RequestPool...
...done
Credentials contain offline signing keys. Use garage-sign to push root ref
Signing package.
Saved keys to tuf/work/keys/{targets.sec, targets.pub}
Finished init for work using /builder/credentials.zip
Pulled targets
added target to tuf/work/roles/unsigned/targets.json
signed targets.json to tuf/work/roles/targets.json
Pushing signature.
Pushed targets
Package torizon/torizon-core-docker-custom Version ad7f57ec73e1dd863b7d822f4d4e0949ed643315508aa297f8b14ed003aee7d5 has been uploaded.
```

Once the operation is completed you should see a new package appearing in the HERE OTA Connect! user interface, ready to be deployed to device.
