#!/bin/bash
#
# Environment variables sources by build scripts

VMNAME="Fedora-18-x86_64-DVD"
VMHOME="/var/lib/libvirt/images/"
TMPDIR="/home/kojak"
DIST="RedHat/Fedora/18/0/x86_64"

DVDISO="Fedora-18-x86_64-DVD.iso"
KS_ISO="Fedora-18-x86_64-DVD.iso"
KS_CFG="Fedora-18-x86_64.cfg"

MNTDIR="${TMPDIR}/mnt/${DIST}"
OPTDIR="${TMPDIR}/opt/${DIST}"
CFGDIR="${TMPDIR}/cfg/${DIST}"
BLDDIR="${TMPDIR}/bld/${DIST}"
ISODIR="${TMPDIR}/iso/${DIST}"

