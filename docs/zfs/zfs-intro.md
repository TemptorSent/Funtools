## Why ZFS?
Because you love your data. ZFS checksums your data and metadata from top to bottom.


## What is ZFS?
ZFS is a complete storage stack, from raw storage devices to hierarchical filesystem mangement.

#### What tools do I need to learn?
You need only two tools to setup and administer ZFS in most cases: `zpool`and `zfs`

#### What is a 'vdev'?
"A "virtual device" describes a single device or a collection of devices organized according to certain performance and fault characteristics." - zpool(8)

#### What types of vdevs are supported?
The disk, file, mirror, raidz1, raidz2, raidz3, spare, log, and cache types are supported (The use of files as a backing store is strongly discouraged - primarily for experimental purposes, - zpool(8) ).

#### What is a pool?
"A storage pool is a collection of devices that provide physical storage and data replication for ZFS datasets. All datasets within a storagepool share the same space." - zpool(8)

#### What is a dataset?
A dataset is a hierarchical labeled filesystem, volume, snapshot, or bookmark stored on a ZFS storage pool.

#### What is a filesystem in ZFS-speak?
A filesystem is dynamically allocated storage which can be mounted within the standard system and behaves like other filesystems (more or less).

#### What is a zvol?
A zvol is a volume with a fixed size storage allocation exported as a raw virtual block device.

#### What is a snapshot?
A snapshot preserves a read-only point-in-time view of the filesystem at the moment you take it which can be viewed or rolled-back to at any time.

#### What is a bookmark?
A bookmark is a non-permanent snapshot useful for maintaining an atomic moment-in-time for sending backups.

#### What is a clone?
A clone is a dataset derrived from another which only requires storing the differences between the parent and child, not new copies of every block.

## How does ZFS relate to what I'm used to?
### ZFS replaces:
#### Hardware RAID controllers / sofware RAID drivers (md)
#### Partitioning tools on whole-disk configurations (*mostly, boot manager may require additional configuration)
#### Logical volume managers (LVM2)
#### Filesystems (ext4, xfs, etc)
#### /etc/fstab entries
#### mount
#### fsck
#### Backup tools (tar, rsync)
#### Network sharing configuration files (nfs&samba)
#### File-backed virtual block devices
