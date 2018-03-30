####
###  FUNTOOL
###
###  Tool for installing and configuring funtoo.
####

# Tool: funtool

# Setup variables for locations to various tools we need.

# Die, with optional message.
# die [message]
die() {
	[ $# -gt 0 ] && printf -- "%s\n" "$*"
	exit 1
}

# Placeholder function for multitool
tool_funtool() {
	return 0
}

# Future external interface
funtool() {
	ALTROOT=
	ALTROOT_ARCH=
	if [ -z "${ALTROOT}" ] && [ "${cmd}" != init ] ; then
		printf -- "Please run '$0 init </path/to/altroot> [arch]' first.\n"
		return 1
	fi
}

funtool_install_usage() {
	:
}

funtool_install() {
	:
}


#
funtool_install_default() {

	fs_create_script="$(zfstool script create from-file "$my_zfs_layout")"
	eval "${fs_create_script}"

	altroot init --mount "zfs:$my_zfs_root" --tarball "$my_funtoo_tarball" "$my_altroot"
	altroot untar "$my_altroot" "$my_settings_tarball"
	altroot untar "$my_altroot" "$my_scripts_tarball"
	altroot chroot "$my_altroot" /._funtool_install_/scripts/update-funtoo.sh
	altroot chroot "$my_altroot" /._funtool_install_/scripts/install-kernel.sh
	altroot chroot "$my_altroot" /._funtool_install_/scripts/install-bootloader.sh
	altroot teardown "$my_altroot"
}

