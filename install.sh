#!/bin/bash
# 
# Copyright (C) 2013 Red Hat Inc.
# Author <sal@redhatcom>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
###############################################################################

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

cp kojak_ks.cfg $CFGDIR/

./vm_create.sh
