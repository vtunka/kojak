#!/bin/bash
# Simple script to install a vm

set -x
source ./env_vars.sh

cd ${VMHOME}

virsh destroy ${VMNAME}
virsh undefine ${VMNAME}

rm ${VMHOME}/${VMNAME}.img

fallocate -l 24576M ${VMHOME}/${VMNAME}.img
chown qemu:qemu ${VMHOME}/${VMNAME}.img

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
--initrd-inject=./kojak_ks.cfg \
--extra-args="ks=file:kojak_ks.cfg console=tty0 console=ttyS0,115200 serial rd_NO_PLYMOUTH" \
--nographics

