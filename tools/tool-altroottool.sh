####
###  ALTROOTTOOL
###
###  Tool for managing alternate root configurations.
####

# Tool: altroottool

# Setup variables for locations to various tools we need.

# Die, with optional message.
# die [message]
die() {
	[ $# -gt 0 ] && printf -- "%s\n" "$*"
	exit 1
}

# Placeholder function for multitool
tool_altroottool() {
	return 0
}

# Future external interface
altroottool() {
	ALTROOT=
	ALTROOT_ARCH=
	if [ -z "${ALTROOT}" ] && [ "${cmd}" != init ] ; then
		printf -- "Please run '$0 init </path/to/altroot> [arch]' first.\n"
		return 1
	fi
}

# altroot_init [--arch <ARCH>] [--mount <SOURCE>] [--tarball <TARBALL>] <ALTROOT>
altroot_init() {
	local my_altroot my_altrootdir my_arch my_mount my_tarball
	my_mount=""
	my_tarball=""
	while [ $# -gt 1 ] ; do
		case "$1" in
			--arch) shift ; my_arch="${1}" ; shift ;;
			--mount) shift ; my_mount="${1}" ; shift ;;
			--tarball) shift ; my_tarball="${1}" ; shift ;;
			--*) die "Unrecognized option '${1}'." ;;
		esac
	done

	# Create directory for mountpoint and mount using helper for tagged sources as needed.
	my_altroot="${1%%/}"
	altroot_init_mount "${my_altroot}" "${my_mount}"
	my_altroot="$(realpath -e "${my_altroot}")" ; [ $? -eq 0 ] || die "Altroot '${my_altroot}' doesn't exits!" ; shift
	my_altrootdir="${my_altroot}/._altroot_"
	test -z "${my_tarball}" || altroot_untar "${my_altroot}" "${my_tarball}"
}

# altroot_untar <altroot> <tarball>
altroot_untar() {
	local my_altroot my_tarball

	my_altroot="$(realpath -e "${1}")" ; [ $? -eq 0 ] || die "Altroot '${1}' doesn't exits!" ; shift
	my_altrootdir="${my_altroot}/._altroot_"

	my_tarball="${1}" ; shift
	my_tbname="${my_tarball##*/}"

	1>/dev/null 2>&1 grep -qx "${my_tbname}" "${my_altrootdir}/tarballs-extracted" && return 0

	test -e "${my_tarball}" || die "Tarballd '${my_tarball}' doesn't exist!"
	pushd "${my_altroot}" > /dev/null
	tar -xpaf "${my_tarball}" $@ || die "Couldn't extract '${my_tarball}' to '${my_altroot}'!"
	popd > /dev/null

	printf -- "%s\n" "${my_tbname}" >> "${my_altrootdir}/tarballs-extracted"
}

# altroot_init_mount <altroot> [type:source]
altroot_init_mount() {
	local my_altroot my_altrootdir my_mount

	my_altroot="${1%%/}" ; shift
	my_mount="${1}" ; shift

	# Create directory for our mountpoint if it doesn't exist.
	test -d "${my_altroot}" || mkdir -p "${my_altroot}" || die "Could not create '${my_altroot}'!"
	my_altroot="$(realpath -e "${my_altroot}")" ; [ $? -eq 0 ] || die "Altroot '${my_altroot}' doesn't exits!" ; shift
	my_altrootdir="${my_altroot}/._altroot_"

	# If we'r already mounted...
	if mounttool_is_mounted "${my_altroot}" ; then
		# See if our altroot is already setup, if so we're done here.
		1>/dev/null 2>&1 grep -qx "/" "${my_altrootdir}/mountpoints_mounted" && return 0

	# Otherwise, mount something.
	else
		# If we weren't given a mount option, set up a bind mount to itself so we have a convenient mountpoint to unmount recursively later.
		: "${my_mount:=bind:${my_altroot}}"

		# Mount source on altroot using helper for tagged sources.
		mounttool_mount_tagged "${my_mount}" "${my_altroot}"
	fi

	# Create altrootdir if needed and note the fact that we mounted this mountpoint.
	test -d "${my_altrootdir}" || mkdir -p "${my_altrootdir}"
	printf -- "%s\n" "/" > "${my_altrootdir}/mountpoints-mounted"
}

# altroot_mount <altroot> [options] [source] <target>
altroot_mount() {
	local my_altroot my_args my_src my_type

	# Take first arg as altroot
	my_altroot="$(realpath -e "${1}")" ; [ $? -eq 0 ] || die "Altroot '${1}' doesn't exits!" ; shift
	my_altrootdir="${my_altroot}/._altroot_"

	# Consume all but the last arg into my_args & grab some info on the way.
	while [ $# -gt 1 ] ; do
		my_args="${my_args:+${my_args} }${1}"
		case "${1}" in
			--bind) my_type="bind" ; my_src="${2%%/}" ;;
			--rbind) my_type="rbind" ; my_src="${2%%/}" ;;
		esac
		shift
	done

	# The final arg is the target mountpoint relative to the altroot
	my_altmntpnt="${1##/}"

	1>/dev/null 2>&1 grep -qx "/${my_altmntpnt}" "${my_altrootdir}/mountpoints_mounted" && return 0
	mounttool_is_mounted "${my_altroot}/${my_altmntpnt}" && return 0

	mkdir -p "${my_altroot}/${my_altmntpnt}" || die "Could not create directory for mountpoint '/${my_altmntpnt}' under '${my_altroot}'"

	# Mount using supplied arguments, with target replaced with full path.
	mount ${my_args} "${my_altroot}/${my_altmntpnt}" || die "Failed: 'mount ${my_args} ${my_altroot}/${my_altmntpnt}'"

	# Note that we've mounted this mountpoint for later unmounting.
	printf -- "%s\n" "/${my_altmntpnt}" >> "${my_altrootdir}/mountpoints-mounted"
}


# altroot_unmount <altroot> [options] <target>
altroot_unmount() {
	local my_altroot my_args my_src my_type

	# Take first arg as altroot
	my_altroot="$(realpath -e "${1}")" ; [ $? -eq 0 ] || die "Altroot '${1}' doesn't exits!" ; shift
	my_altrootdir="${my_altroot}/._altroot_"

	# Consume all but the last arg into my_args.
	while [ $# -gt 1 ] ; do my_args="${my_args:+${my_args} }${1}" ; shift ; done

	# The final arg is the target mountpoint relative to the altroot
	my_altmntpnt="${1##/}"

	# Unount using supplied arguments, with target replaced with full path.
	umount ${my_args} "${my_altroot}/${my_altmntpnt}" || die "Failed: 'umount ${my_args} ${my_altroot}/${my_altmntpnt}'"

	# Remove the notation that this mountpoint is mounted.
	sed -e '\|^/'"${my_altmntpnt}"'$|d' -i "${my_altrootdir}/mountpoints-mounted"
}

# altroot_mount_default <altroot>
altroot_mount_default() {
	local my_altroot
	my_altroot="$(realpath -e "${1}")" ; [ $? -eq 0 ] || die "Altroot '${1}' doesn't exits!" ; shift
	altroot_mount "$my_altroot" -t proc none /proc
	altroot_mount "$my_altroot" --rbind /sys /sys
	altroot_mount "$my_altroot" --rbind /dev /dev
}

# altroot_chroot <altroot> [args]
altroot_chroot() {
	local my_altroot
	my_altroot="$1" ; shift

	# Cache our path to chroot binary.
	: "${_altroot_chroot:=$(command -v chroot)}"

	# Initilize the altroot if it's not already
	altroot_init "${my_altroot}"

	# Now that we know it should exist, expand to the proper path for altroot.
	my_altroot="$(realpath "${my_altroot}")"

	# Mount the basics: proc, sys, and dev.
	altroot_mount_default "${my_altroot}"
	altroot_copy "${my_altroot}" "/etc/resolv.conf"

	"$_altroot_chroot" "${my_altroot}" $@
}


# altroot_teardown <altroot>
altroot_teardown() {
	local my_altroot
	my_altroot="$(realpath -e "${1}")" ; [ $? -eq 0 ] || die "Altroot '${1}' doesn't exits!" ; shift

	# Clear the list of mounted mountpoints
	echo "" > "${my_altrootdir}/mountpoints-mounted"

	# Keep running recursive lazy unmount until we're fully unmounted.
	while mounttool_is_mounted "${my_altroot}" ; do
		umount -l -r "$my_altroot"
		sleep 1
	done
}


# altroot_copy <altroot> <source> [target]
altroot_copy() {
	local my_altroot my_args my_src my_type

	# Take first arg as altroot.
	my_altroot="$(realpath -e "${1}")" ; [ $? -eq 0 ] || die "Altroot '${1}' doesn't exits!" ; shift

	# Take second arg as source.
	my_src="$(realpath -e "${1}")" ; [ $? -eq 0 ] || die "Copy source '${1}' doesn't exits!" ; shift

	# The final arg, if given, is the target relative to the altroot, otherwise use the same path as the source.
	my_alttgt="${1:-${my_src}}"

	# Clean up path to have a single leading '/' and none trailing.
	my_alttgt="/${my_alttgt##/}" ; my_alttgt="${my_alttgt%%/}"

	# Copy source to target with full path.
	my_tgt="${my_altroot}/${my_alttgt##/}"
	mkdir -p "${my_tgt%/*}"
	cp -a "${my_src}" "${my_tgt}"
	

	# Remove the notation that this mountpoint is mounted.
	printf -- "%s\t%s\n" "${my_src}" "${my_alttgt}" >> "${my_altrootdir}/items-copied"
}



# Most of this logic belongs in zfstool :)
# Need to add snapshot/clone handling too
# _altroot_zfs_mount <altroot> <dataset> <altroot-mountpoint>
_altroot_zfs_mount() {
	local my_altroot my_ds my_parent my_altmntpt my_mountpoint
	my_altroot="${1%%/}" ; shift
	my_ds="$1" ; my_parent="${my_ds%/*}" ; shift
	my_altmntpt="${1##/}"
	my_mountpoint="${my_altroot}/${my_altmntpt}"

	my_ds_exists="$(zfstool_zfs get -H -o value name "${my_ds}" 2>&1 > /dev/null && echo true || echo false)"
	my_parent_exists="$(zfstool_zfs get -H -o value name "${my_parent}" 2>&1 > /dev/null && echo true || echo false)"

	# If the dataset doesn't exist, create it if possible.
	if ! $my_ds_exists ; then
		# If the parent to our proposed dataset exists, then create our new dataset.
		if $my_parent_exists ; then
			local my_parent_mountpoint
			my_parent_mountpoint="$(zfstool_zfs get -H -o value mountpoint "${my_parent}")"

			# If we can inherit the parent mountpoint, let's do so.
			if [ "${my_mountpoint}" = "${my_parent_mountpoint%%/}/${my_altmntpt}" ] ; then
				zfstool_zfs create "${my_ds}" || die "Failed to create dataset '${my_ds}'!"
			# Othewise, explicitly specifiy mountpoint for new dataset.
			else
				zfstool_zfs create -o mountpoint="${my_mountpoint}" "${my_ds}" || die "Failed tor create dataset '${my_ds}' with mountpoint '${my_mountpoint}'!"
			fi
		# If the parent doesn't exist, we're not going to build the tree up, so bail out.
		else
			die "No existing dataset '${my_ds}', nor parent '${my_parent}' dataset under which to create a new dataset."
		fi
	fi

	# Since we made it here, the dataset already exists, so let's see about mounting it, if needed.
	local my_zcanmount my_zmountpoint my_zmounted
	my_zcanmount="$(zfstool_zfs get -H -o value canmount "${my_ds}")"
	my_zmountpoint="$(zfstool_zfs get -H -o value mountpoint "${my_ds}")"
	my_zmounted="$(zfstool_zfs get -H -o value mounted "${my_ds}")"

	# Don't try to mount canmount=no dataset.
	if [ "${my_zcanmount}" = "no" ] ; then return 1 ; fi
	# Don't try to change mountpoint for mounted dataset.
	if [ "${my_zmounted}" = "yes" ] && [ "${my_zmountpoint}" != "${my_mountpoint}" ] ; then return 1 ; fi
	# Don't try to mount again if we're already mounted on the right mountpoint.
	if [ "${my_zmounted}" = "yes" ] && [ "${my_zmountpoint}" = "${my_mountpoint}" ] ; then return 0 ; fi

	# Handle legacy mountpoints
	if [ "${my_zmountpoint}" = "legacy" ] ; then
		mount -t zfs "${my_ds}" "${my_mounpoint}" || die "Could not mount zfs filesystem '${my_ds}' with \"legacy\" mountpoint set to '${my_mountpoint}'!"
		return $?
	fi

	# Change our mountpoint if needed
	if [ "${my_zmountpoint}" != "${my_mountpoint}" ] ; then
		zfstool_zfs set mountpoint="${my_altroot}" "${my_ds}" || die "Could not set mountpoint on dataset '${my_ds}' to  '${my_mountpoint}'!"
		my_zmounted="$(zfs get -H -o value mounted "${my_ds}")"
	fi

	# If we're successfully mounted at this point, return true.
	[ "${my_zmounted}" = "yes" ] && return 0

	# Otherwise attempt to mount and return the result.
	zfstool_zfs mount "${my_mountpoint}" ; return $?
}


### FIXME: This needs to move to mounttool (or fstool?)

mounttool_mount_tagged() {
		local my_srctagged my_dest my_type my_src

		my_srctagged="${1}"
		shift
		my_dest="${1%%/}"
		
		my_type="${my_srctagged%%:*}"
		my_src="${my_srctagged#*:}" ; [ "${my_src}" = "/" ] || my_src="${my_src%%/}"

		# Parse the --mount option into type:source auto, or source
		case "$my_srctagged" in
			zpool:*) zfstool_zpool_import -o altroot="${my_dest}" -o cachefile="/tmp/${my_src}" "${my_src}" ;;
			zfs:*) zfstool_zfs_mount "${my_src}" "${my_dest}" ;;
			bind:*) mounttool_mount_bind "${my_src}" "${my_dest}" ;;
			rbind:*) mounttool_mount_rbind "${my_src}" "${my_dest}" ;;
			*:*) mounttoool_mount_type ${my_type} "${my_src}" "${my_dest}" ;;
			auto) mountoool_mount_auto "${my_dest}" ;;
			*) mounttool_mount_auto "${my_src}" "${my_dest}" ;;
		esac

}

mounttool_mount_bind() {
	local my_src my_dest
	my_src="${1%%/}" ; shift
	my_dest="${1%%/}" ; shift

	mount --bind "${my_src}" "${my_dest}"
}

mounttool_mount_rbind() {
	local my_src my_dest
	my_src="${1%%/}" ; shift
	my_dest="${1%%/}" ; shift

	mount --rbind "${my_src}" "${my_dest}"
}

mounttool_mount_type() {
	local my_type my_src my_dest
	my_type="${1}" ; shift
	my_src="${1%%/}" ; shift
	my_dest="${1%%/}" ; shift

	mount -t ${type} "${my_src}" "${my_dest}"
}

mounttool_mount_auto() {
	mount $@
}

mounttool_is_mounted() {
	local my_mountpoint
	my_mountpoint="$(realpath "${1}")" ; shift
	awk 'BEGIN { out=1; } $2 == "'"${my_mountpoint}"'" { out=0 } END { exit out; }' /proc/mounts
	return $?
}


