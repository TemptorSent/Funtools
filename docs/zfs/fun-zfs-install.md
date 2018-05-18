Installation of Funtoo on ZFS
=============================


## Preparation
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
	mkdir -p etc/zfs
	cp /tmp/zpool.cache etc/zfs/zpool.cache

#### Copy resolve.conf to /etc under the target root:
	cp /etc/resolv.conf etc/
	
	
## chroot Enviornment

### chroot

#### Enter the chroot environment:
	env -i HOME=/root TERM=$TERM /bin/chroot . bash -l

#### Set a prompt to remind us we're in the chroot:
	export PS1="(chroot) $PS1"

#### Change PWD to root's home directory (/root):
	cd
	
### /etc/fstab

#### Empty out /etc/fstab:
	sed -i '1 q' /etc/fstab
	echo -e '# <Device>\t<Mountpoint>\t<Type>\t<Mount Options>\t<Dump/Pass>' >> /etc/fstab

#### Add swap entry for rpool/SWAP/swap0 if it was (optionally) created previously:
	echo -e '/dev/zvol/rpool/SWAP/swap0\tnone\tswap\tsw\t0 0' >> /etc/fstab

#### Sync and update portage tree:
	ego sync
	env-update
	. /etc/profile
	
Note: bug fix was needed upstream, because ego refused to checkout to existing empty /var/git/meta-repo; if above fails, use the following workaround for first `ego sync` and file a bug upstream:

		# Workaround for ego sync refusing to sync to empty directory
		# This should no longer be needed.
		zfs rename rpool/FUNTOO/meta-repo rpool/FUNTOO/meta-repox
		ego sync
		(cd /var/git/meta-repo && rsync -aAX . /var/git/meta-repox)
		rm -r meta-repo
		zfs rename rpool/FUNTOO/meta-repox rpool/FUNTOO/meta-repo



### /etc/portage

#### Create directories for package.* instead of using monolithic files:
	mkdir /etc/portage/package.{accept_keywords,accept_restrict,env,keywords,license,mask,properties,unmask,use}


### BUG: debian-sources has no way of preventing it from overwriting the /usr/src/linux symlink if you have a custom kernel installed -- this WILL break your system if you're not careful!
#### Install kernel sources:
	echo -e "# Required by debian-sources\napp-arch/xz-utils\tapi_x86_32" >> /etc/portage/package.use/xz-utils
	emerge -1v sys-kernel/debian-sources

#### Install ZFS components:
	emerge -v sys-kernel/spl sys-fs/zfs sys-fs/zfs-kmod
	
#### Start zfs-import and zfs-mount early in boot process:
	rc-update add zfs-import sysinit
	rc-update add zfs-mount sysinit

#### Start zfs-zed and zfs-share in the default runlevel:
	rc-update add zfs-zed default
	rc-update add zfs-share default

### grub
#### Install grub using libzfs:
	echo -e "# Require for booting from ZFS\nsys-boot/grub:2\tlibzfs" >> /etc/portage/package.use/grub
	emerge sys-boot/grub:2
#### Create /etc/mtab and make sure grub understands zfs
	touch /etc/mtab
	[ "$(grub-probe /)" = "zfs" ] || echo "Grub could not detect zfs filesystem at '/'!"

#### Install the bootloader to all drives in the array:
Note: Replace `/dev/disk/by-id/...` with wildcard match or list of devices for your pool.

	for drive in /dev/disk/by-id/... ; do
		sgdisk -a1 -n2:48:2047 -t2:EF02 -c2:"BIOS boot partition" $drive
		partx -u $drive
		grub-install $drive
	done

### Install `dracut` and build initramfs:
Note: Mount `/boot` if it's not mounted for some reason...
	emerge sys-kernel/dracut
	(cd /boot & dracut --force)

### Configure the bootloader entries:
Note: Need simple example bootloader config for grub here.
Note: dracut use the format `root=zfs:pool/path/TO/rootfs` to specify the root filesystem.


### Configure the system

#### Install logger:
	emerge app-admin/metalog
	rc-update add metalog default

#### Set root's password:
	passwd
	
### Leave the chroot
#### Exit the chrooted shell:
	exit


## Finishing up

#### Unbind /dev, /proc, and /sys from target root:
	umount -lR {dev,proc,sys}
	
#### Disable Swap (required if enabled):
	swapoff -a
	
#### Change out of the target root directory so it's not busy when we try to export:
	cd /
	
#### Export the pool:
	zpool export rpool
