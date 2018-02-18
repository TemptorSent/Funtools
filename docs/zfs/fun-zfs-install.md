Installation of Funtoo on ZFS
=============================


### Preparation
Note: This assumes your root pool is mounted with it's altroot set to /mnt/funtoo

#### Enable Swap (optional):
	mkswap -L swap0 /dev/zvol/rpool/SWAP/swap0
	swapon LABEL=swap0

#### Change to the directory where the pool's altroot is mounted:
	cd /mnt/funtoo
	
#### Fetch and extract Funtoo stage3 tarball:
Note: Replace 'generic_64' in the URL with your subarch, see https://www.funtoo.org/Subarches.

	get https://build.funtoo.org/funtoo-current/x86-64bit/generic_64/stage3-latest.tar.xz
	tar -xvpaf stage3-latest.tar.xz

#### Bind mount proc, sys, and dev into the target root:
	mount -t proc none proc
	mount --rbind /sys sys
	mount --rbind /dev dev

#### Copy zpool cache to /etc/zfs under the target root:
	mkdir -p /mnt/funtoo/etc/zfs
	cp /tmp/zpool.cache ./etc/zfs/zpool.cache

#### Copy resolve.conf to /etc under the target root:
	cp /etc/resolv.conf ./etc/
	
### chroot Enviornment


### Finishing up

#### Unbind /dev, /proc, and /sys from target root:
	umount -lR {dev,proc,sys}
	
#### Disable Swap (required if enabled):
	swapoff -a
	
#### Change out of the target root directory so it's not busy when we try to export:
	cd /
	
#### Export the pool:
	zpool export rpool
