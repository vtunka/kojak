#!/bin/bash
#
# Environment varibles sources by build scripts

VMNAME="Fedora-18-x86_64-DVD"
VMHOME="/mnt/media/USB0"
DIST="RedHat/Fedora/18/0/x86_64"

DVDISO="Fedora-18-x86_64-DVD.iso"
KS_ISO="Fedora-18-x86_64-DVD.iso"
KS_CFG="Fedora-18-x86_64.cfg"

MNTDIR="${VMHOME}/mnt/${DIST}"
OPTDIR="${VMHOME}/opt/${DIST}"
CFGDIR="${VMHOME}/cfg/${DIST}"
BLDDIR="${VMHOME}/bld/${DIST}"
ISODIR="${VMHOME}/iso/${DIST}"
IMGDIR="${VMHOME}/img/${DIST}"

