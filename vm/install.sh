#!/bin/bash
#
# Simple script to set up the environment

set -x
source ./env_vars.sh

mkdir -p $MNTDIR $OPTDIR $CFGDIR $BLDDIR $ISODIR $IMGDIR


if [ -e "$ISODIR/Fedora-18-x86_64-DVD.iso" ]; then
    echo "DVD ISO Found"
else
    echo "Downloading DVD ISO"
    cd $ISODIR
    wget http://download.fedoraproject.org/pub/fedora/linux/releases/18/Fedora/x86_64/iso/Fedora-18-x86_64-DVD.iso
    cd -
fi

tree $TMPDIR
