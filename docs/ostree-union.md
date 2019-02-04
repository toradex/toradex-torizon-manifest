# Create OSTree Union

This document describes how to modify files inside OSTree

## First time creation of repositories

### Requirements
1. Have existing ostree ( for example Toradex one ) 
2. Create new folder structure that you need

#### Pull Toradex ostree to your local folder

Commands below will init new ostree repository inside folder **toradex-os-tree** and add new remote called toradex. In last step it will pull branch **torizon/torizon-core-docker**. Depth 1 means only latest commit.
```
mkdir toradex-os-tree
ostree --repo=toradex-os-tree init --mode=bare-user 
ostree --repo=toradex-os-tree remote add toradex  http://feeds.toradex.com/ostree/nightly/colibri-imx7/ --no-gpg-verify 
ostree --repo=toradex-os-tree pull toradex torizon/torizon-core-docker --depth=1
```
- Create folder for your changes
```
mkdir my-changes
```
#### Add files you require for example
```
my-changes
└── etc
        └── text.txt
echo "test" > my-changes/etc/test.txt
```

#### Commit changes to existing ostree repository, creating new branch called *my-changes*
```
ostree --repo=toradex-os-tree commit -b my-changes --tree=dir=my-changes 
```

#### Checkout Toradex ostree to rootfs. This will checkout rootfs from ostree repository to **temporary-rootfs**

```
ostree --repo=toradex-os-tree checkout -U --union torizon/torizon-core-docker temporary-rootfs    
```

#### Now checkout new branch and union it with temporary-rootfs
```
ostree --repo=toradex-os-tree checkout -U --union my-changes temporary-rootfs
```
#### Now commit all our changes back to ostree with new branch name *final-ostree*

```
ostree --repo=toradex-os-tree commit -b final-ostree --tree=dir=temporary-rootfs 
```
#### update information about ostree in summary file
```
ostree --repo=toradex-os-tree summary -u
```

This OSTree can now be deployed to supported devices.

__Note: when doing multiple changes it is wise to always commit back to same branch. This was history is tracked as it should be.__


## Making changes on already existing structure

### Requirements
1. This part considers that one time configuration was set and folder structure is the same

#### Modify content of a file
```
echo "test2" > my-changes/etc/test.txt
```
#### Commit changes to existing ostree repository, to branch called *my-changes*
```
ostree --repo=toradex-os-tree commit -b my-changes --tree=dir=my-changes 
```

#### Check ostree diff
Running this command will return status of OSTree
```
ostree --repo=toradex-os-tree diff my-changes
```
Output:
```
> ostree --repo=toradex-os-tree diff my-changes     
M    /etc/test.txt
```
#### Checkout new changes and union it with temporary-rootfs
```
ostree --repo=toradex-os-tree checkout -U --union my-changes temporary-rootfs
```

#### Commit changes back to ostree with new branch name *final-ostree*
```
ostree --repo=toradex-os-tree commit -b final-ostree --tree=dir=temporary-rootfs 
```
#### Update information about ostree in summary file
```
ostree --repo=toradex-os-tree summary -u
```