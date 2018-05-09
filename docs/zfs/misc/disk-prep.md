# ZFS Disk Preparation

### Using sgdisk and wipefs tools

##### If giving entire disks to ZFS, it is a good idea first to use some disk tools to remove various remnants from previous operating system installations. If using new disks for the first time, none of what follows should be necessary.

#### WARNING: The following commands will make any existing data on the specified drive inaccesable, but will not securely delete it! If you would like to securely erase data, use a secure erase tool, such as nwipe.

##### "Clear out all partition data. This includes GPT header data, all partition definitions, and the protective MBR." - sgdisk(8)
sgdisk --clear /dev/disk/by-id/...

##### "Erase all available signatures." - wipefs(8)
wipefs --all /dev/disk/by-id/...
