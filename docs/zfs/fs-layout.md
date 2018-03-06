# ZFS Dataset Layout


### Pool setup

#### Define a variable with the pool device layout in the form of one of the following:
##### `ZVDEVS_rpool="mirror /dev/disk/by-id/... /dev/disk/by-id/..."`
##### `ZVDEVS_rpool="mirror /dev/disk/by-id/... /dev/disk/by-id/... mirror /dev/disk/by-id/... /dev/disk/by-id/..."`
##### `ZVDEVS_rpool="raidz1 /dev/disk/by-id/... /dev/disk/by-id/... /dev/disk/by-id/..."`
##### `ZVDEVS_rpool="raidz2 /dev/disk/by-id/... /dev/disk/by-id/... /dev/disk/by-id/... /dev/disk/by-id/..."`
##### `ZVDEVS_rpool="raidz3 /dev/disk/by-id/... /dev/disk/by-id/... /dev/disk/by-id/... /dev/disk/by-id/... /dev/disk/by-id/..."`
##### `ZVDEVS_rpool="raidz1 /dev/disk/by-id/... /dev/disk/by-id/... /dev/disk/by-id/... raidz1 /dev/disk/by-id/... /dev/disk/by-id/... /dev/disk/by-id/..."`

##### ...and so forth. See zpool(8) for further details.

#### Create the pool:
	zpool create -f -o ashift=12 -o cachefile=/tmp/zpool.cache -O compression=lz4 -O atime=on -O relatime=on -O normalization=formD -O xattr=sa -m none -R /mnt/funtoo rpool ${ZVDEVS_rpool}

    
##### Note: For SSD pools, consider using `-O atime=off` instead to further reduce number of writes; may confuse progams like mail clients in some cases. 
##### Note: See https://github.com/zfsonlinux/zfs/issues/443 for details on xattr=sa.


### SWAP Dataset (optional)

#### Create a base dataset to hold swap zvols
##### Note: See https://forum.proxmox.com/threads/proxmox-5-change-from-zfs-rpool-swap-to-standard-linux-swap-partition.36376/.

	zfs create -o primarycache=metadata -o secondarycache=metadata -o compression=zle -o sync=always -o logbias=throughput rpool/SWAP

#### Create a 4GB zvol to use for swap
	zfs create -V 4G -b $(getconf PAGESIZE) rpool/SWAP/swap0


### ROOT Dataset

#### Create the base dataset for boot environments:
	zfs create -o mountpoint=none -o canmount=off rpool/ROOT

#### Create your initial system boot environment root:
	zfs create -o mountpoint=/ canmount=on rpool/ROOT/funtoo

#### Set your system root as the bootfs for the pool
	zpool set bootfs=rpool/ROOT/funtoo

#### Create your system filesystem hierarchy:
	zfs create rpool/ROOT/funtoo/var
	zfs create rpool/ROOT/funtoo/var/git
	zfs create rpool/ROOT/funtoo/opt
	zfs create rpool/ROOT/funtoo/srv


### BOOT Dataset

#### Create the base dataset for files under /boot:
	zfs create -o compression=off -o mountpoint=/ -o canmount=off -o sync=always rpool/BOOT

#### Create datasets for common /boot:
	zfs create -o canmount=on rpool/BOOT/boot

#### Create dataset for grub at /boot/grub:
	zfs create rpool/BOOT/boot/grub


### ROOT Dataset (After /boot creation)

#### Create an unmountable dataset at /boot in the boot environment:
	zfs create -o canmount=off -o sync=always rpool/ROOT/funtoo/boot
	
#### Create dataset mounted at /boot/active for boot-environment specific boot files:
	zfs create -o canmount=on rpool/ROOT/funtoo/boot/active


### TMP Dataset

#### Create a base dataset for temporary directories:
	zfs create -o mountpoint=/ -o canmount=off rpool/TMP

#### Create unmnountable datasets rpol/TMP/var for parent directory of /var/tmp:
	zfs create -o canmount=off rpool/TMP/var

#### Create mountable datasets for various temp directories:
	zfs create -o canmount=on rpool/TMP/tmp
	zfs create -o canmount=on rpool/TMP/var/tmp
	zfs create -o canmount=on -o sync=disabled rpool/TMP/var/tmp/portage


### HOME Dataset

#### Create a base dataset for users home directories:
	zfs create -o mountpoint=/ -o canmount=off rpool/HOME

#### Create the /home directory root:
	zfs create -o canmount=on rpool/HOME/home

#### Create root's home directory at /root:
	zfs create -o canmount=on rpool/HOME/root


### FUNTOO Dataset

#### Create a base dataset for Funtoo specific stuff:
	zfs create -o mountpoint=/ -o canmount=off rpool/FUNTOO

#### Create unmnountable datasets for parent directories of our desired leaf nodes:
	zfs create -o canmount=off rpool/FUNTOO/var
	zfs create -o canmount=off rpool/FUNTOO/var/cache
	zfs create -o canmount=off rpool/FUNTOO/var/git

#### Create mountable datasets for our desired leaf nodes:
	zfs create -o canmount=on rpool/FUNTOO/var/cache/distfiles
	zfs create -o canmount=on rpool/FUNTOO/var/git/meta-repo
