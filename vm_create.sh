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

# Verbose output 
set -x

# See env_vars.sh for varible assignments
source ./env_vars.sh

cd ${VMHOME}

# Remove any pre-existing vm with the same name
virsh destroy ${VMNAME}
virsh undefine ${VMNAME}

# Remove any pre-existing vm image with the same name
rm ${VMHOME}/${VMNAME}.img

# Allocate the diskspace for the vm
fallocate -l 24576M ${VMHOME}/${VMNAME}.img
chown qemu:qemu ${VMHOME}/${VMNAME}.img

# Create the vm with the following options
virt-install \
-n ${VMNAME} \
-r 4096 \
--vcpus=2 \
--os-type=linux \
--os-variant=fedora18 \
--accelerate \
--mac=00:00:00:00:00:00 \
--disk=${VMHOME}/${VMNAME}.img \
--disk=${ISODIR}/${KS_ISO},device=cdrom \
--location ${ISODIR}/${KS_ISO} \
--initrd-inject=${CFGDIR}/kojak_ks.cfg \
--extra-args="ks=file:kojak_ks.cfg console=tty0 console=ttyS0,115200 serial rd_NO_PLYMOUTH" \
--nographics

