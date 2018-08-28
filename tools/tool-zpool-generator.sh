#!/usr/bin/env bash

# Copyright 2018 Funtools
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Fill in variables below and execute script from a live disk that has zfs support.

#################
# set variables #
#################

# Pool name preference, e.g. rpool or zroot
POOL_NAME="rpool"

# leave empty "" for single disk or use "mirror", "raidz1", "raidz2", or "raidz3"
POOL_TYPE="mirror"

# It is recommended to list disks using /dev/disk/by-id (instead of e.g. /dev/sda /dev/sdb ...
# It is also recommended to give ZFS entire disks, they will be GPT partitioned automatically by ZFS.
POOL_DISKS="
/dev/sda
/dev/sdb
"

# The 32-bit host ID of the machine, formatted as 8 hexadecimal characters.
# You should try to make this ID unique among your machines.
# FIXME not finished
POOL_HOSTID="random"

# Set to 1 if the disk(s) are not brand new.
REMOVE_REMNANTS="true"

# Set ATIME to "on" or "off". Not using atime can increase SSD disk life.
ATIME="off"

# Apply com.sun:auto-snapshot=true attributes to ROOT or HOME datasets?
SNAPSHOT_ROOT="true"
SNAPSHOT_HOME="true"

#################
# defun ()      #
#################

__initial_warning() {
    echo "WARNING: The following script intends to replace all of your disk(s) \
contents with a fresh zfs-on-root layout."
    echo ""
    read -p "Continue? (Y or N) " -n 1 -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        echo "Aborted." ; exit
    fi
}

__uefi_or_legacy() {
    if [ -d "/sys/firmware/efi/efivars" ]; then
        exit ; echo "eww efi..."
        echo "uefi is currently unsupported by this script. Using legacy bios is recommended if you can help it."
    fi
}

__disk_prep() {
    if [[ ${REMOVE_REMNANTS} == "true" ]]
    then
        IFS=$'\n'
        for DISK_ID in ${POOL_DISKS}
        do
            sgdisk --clear ${DISK_ID}
            wipefs --all ${DISK_ID}
        done
    fi
}

__zpool_create() {
    zpool create -f \
          -o ashift=12 \
          -o cachefile=/tmp/zpool.cache \
          -O compression=lz4 \
          -O atime=${ATIME:?"Please define atime."} \
          -O relatime=on \
          -O normalization=formD \
          -O xattr=sa \
          -m none \
          -R /mnt \
          ${POOL_NAME:?"Please define pool name."} \
          ${POOL_TYPE} \
          ${POOL_DISKS:?"Please define pool disks."}

    IFS=$'\n'
    for DISK_ID in ${POOL_DISKS}
    do
        sgdisk -a1 -n2:48:2047 -t2:EF02 -c2:"BIOS boot partition" ${DISK_ID}
        partx -u ${DISK_ID}
    done
}

__datasets_create() {
    # / (root) datasets
    zfs create -o mountpoint=none -o canmount=off -o sync=always ${POOL_NAME}/ROOT
    zfs create -o mountpoint=/ -o canmount=on ${POOL_NAME}/ROOT/funtoo
    zpool set bootfs=${POOL_NAME}/ROOT/funtoo ${POOL_NAME}

    # /home datasets
    zfs create -o mountpoint=none -o canmount=off ${POOL_NAME}/HOME
    zfs create -o mountpoint=/home -o canmount=on ${POOL_NAME}/HOME/home

    # /tmp datasets
    zfs create -o mountpoint=none -o canmount=off ${POOL_NAME}/TMP
    zfs create -o mountpoint=/tmp -o canmount=on -o sync=disabled ${POOL_NAME}/TMP/tmp
}

__zfs_auto_snapshot() {
    if [[ ${SNAPSHOT_HOME} == "true" ]]
    then
        zfs set com.sun:auto-snapshot=true ${POOL_NAME}/HOME
    elif [[ ${SNAPSHOT_ROOT} == "true" ]]
    then
        zfs set com.sun:auto-snapshot=true ${POOL_NAME}/ROOT
    fi
}

__zfs_hostid() {
    if [[ ${POOL_HOSTID} == "random" ]]
    then
        POOL_HOSTID="$(head -c4 /dev/urandom | od -A none -t x4 | cut -d ' ' -f 2)"
    else
        echo
    fi
}

__thank_you() {
    cat <<EOF
                  ___          ___                 ___          ___
      ___        /  /\        /  /\    ___        /  /\        /  /\
     /  /\      /  /:/       /  /::|  /__/\      /  /::\      /  /::\
    /  /::\    /  /:/       /  /:|:|  \  \:\    /  /:/\:\    /  /:/\:\
   /  /:/\:\  /  /:/       /  /:/|:|__ \__\:\  /  /:/  \:\  /  /:/  \:\
  /  /::\ \:\/__/:/     /\/__/:/ |:| /\/  /::\/__/:/ \__\:\/__/:/ \__\:\
 /__/:/\:\ \:\  \:\    /:/\__\/  |:|/:/  /:/\:\  \:\ /  /:/\  \:\ /  /:/
 \__\/  \:\_\/\  \:\  /:/     |  |:/:/  /:/__\/\  \:\  /:/  \  \:\  /:/
      \  \:\   \  \:\/:/      |__|::/__/:/      \  \:\/:/    \  \:\/:/
       \__\/    \  \::/       /__/:/\__\/        \  \::/      \  \::/
                 \__\/        \__\/               \__\/        \__\/
EOF
}


#################
# Action !      #
#################

__uefi_or_legacy # TODO add uefi support.
__initial_warning
__disk_prep
__zpool_create
__datasets_create # TODO temptorsent: please fix to your style in https://github.com/TemptorSent/Funtools/blob/master/docs/zfs/fs-layout.md
__zfs_auto_snapshot
__zfs_hostid #TODO (incomplete)
__thank_you
