Funtools - Overview
====================
A toolbox for Funtoo Linux
---------------------------

Rescue/Install Disk
===================

Install Configuration Tool
==========================


Filesystem Setup Tool
=====================

ZFS
----

* Create new pool or install to existing.
* Import using ZFS send/receive.
* Allow custom layout.
* Have sane default layout with structure that supports multiple BEs.
* Seperate system datasets from local datasets.
* Provide funtoo-specific dataset layout.

Network Setup Tool
==================


Boot Environment Tool
=====================
* Create new clean boot environment dataset structure.
* Create new boot environment from existing.
* List BEs.
* Take snapshot of a BE.
* Mount/unmount inactive BE on alt root.
* Activate a different BE.
* Destroy a BE.

Bootloader
----------
* Set up bootloader on new boot drive.
* Generate bootloader config.
* Update bootloader when BE changes.
* Provide fallback to recovery console.


Alt Root Tool
=============

* Setup directory strucuture in alternate root location.
* Bind mount / unbind required mounts (/dev, /sys, etc.) into alt root.
* Bind mount / unbind requested directories into alt root.
* Copy required network/fs config files into alt root.
* Start chroot environments in alt root.


Stage3/rootfs Install Tool
==========================
* Select source archive(s) for stage3 or rootfs.
* Select destination root directory.
* Install all or selected files from archive(s).
* Install files from overlay directory.


Kernel Tool
===========

Kernels
-------
* Build and install kernels from source.
* Extract and install binary packaged kernels.
* Maintain archive of .config options for each installed kernel.
* Rebuild kernel to bake in modules, firmware, and/or initramfs image.

Modules
-------
* Build/rebuild kernel and/or external modules.
* Ensure installed kernel version and module versions match.
* Determine dependencies between modules and list dep tree.

Customize Install Tool
======================
* Install funtoo packages.
* Install custom packages.
* Install/modifiy config files.
* Provision services.

Initramfs Tool
==============
* Build initramfs with matched set of kernel and required modules.
* Allow 'initramfs-feature' selection to specify exactly the set of modules and userspace tools to include in initramfs.
* Include recovery console tools (optional).
