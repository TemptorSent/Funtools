ZFS Dataset Layout
==================

### Pool setup

#### Create the pool:
    zpool create -f -o ashift=12 -o cachefile=/tmp/zpool.cache -O normalization=formD  -m none -R /mnt/funtoo rpool raidz2 /dev/disk/by-id/... /dev/disk/by-id/... .....
    
Note: For SSD pools, add `-O atime=off` to the above command to reduce number of writes; may confuse progams like mail clients in some cases.


### SWAP setup (optional)

#### Create a base dataset to hold swap zvols
    zfs create  -o logbias=throughput -o sync=always -o primarycache=metadata rpool/SWAP

#### Create a 2GB zvol to use for swap
    zfs create -V 2G -b $(getconf PAGESIZE) -o logbias=throughput -o sync=always -o primarycache=metadata rpool/SWAP/swap0


### ROOT Base Dataset

#### Create the base dataset for boot environments:
    zfs create -o mountpoint=none -o canmount=off -o compression=lz4 rpool/ROOT

#### Create your initial system boot environment root:
    zfs create -o mountpoint=/ canmount=on rpool/ROOT/funtoo

#### Set your system root as the bootfs for the pool
    zpool set bootfs=rpool/ROOT/funtoo

#### Create your system filesystem hierarchy:
    zfs create rpool/ROOT/funtoo/var
    zfs create rpool/ROOT/funtoo/var/git
    zfs create rpool/ROOT/funtoo/opt
    zfs create rpool/ROOT/funtoo/srv

### TMP Base Dataset

#### Create a base dataset for temporary directories:
zfs create -o compression=lz4 -o mountpoint=/ -o canmount=off rpool/TMP

#### Create unmnountable datasets rpol/TMP/var for parent directory of /var/tmp:
    zfs create -o canmount=off rpool/TMP/var

#### Create mountable datasets for various temp directories:
    zfs create -o canmount=on rpool/TMP/tmp
    zfs create -o canmount=on rpool/TMP/var/tmp
    zfs create -o canmount=on -o sync=disabled rpool/TMP/var/tmp/portage


### HOME Base Dataset

#### Create a base dataset for users home directories:
    zfs create -o compression=lz4 -o mountpoint=/ -o canmount=off rpool/HOME

#### Create the /home directory root:
    zfs create -o canmount=on rpool/HOME/home

#### Create root's home directory at /root:
    zfs create -o canmount=on rpool/HOME/root


### FUNTOO Base Dataset

#### Create a base dataset for Funtoo specific stuff:
zfs create -o compression=lz4 -o mountpoint=/ -o canmount=off rpool/FUNTOO

#### Create unmnountable datasets for parent directories of our desired leaf nodes:
    zfs create -o canmount=off rpool/FUNTOO/var
    zfs create -o canmount=off rpool/FUNTOO/var/cache
    zfs create -o canmount=off rpool/FUNTOO/var/git

#### Create mountable datasets for our desired leaf nodes:
    zfs create -o canmount=on rpool/FUNTOO/var/cache/distfiles
    zfs create -o canmount=on rpool/FUNTOO/var/git/meta-repo
