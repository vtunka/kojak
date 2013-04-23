#!/bin/bash

set -x
source ./env_vars.sh

cd ${VMHOME}

rm -rf ${BLDDIR}/*
rm -rf  rm -rf ${ISODIR}/${KS_ISO}

mount -o loop ${OPTDIR}/${DVDISO} ${MNTDIR}/
cp -r ${MNTDIR}/* ${BLDDIR}/
cp ${CFGDIR}/${KS_CFG} ${BLDDIR}/ks.cfg

cd ${BLDDIR}/

mkisofs -J -R -v -T -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o ${ISODIR}/${KS_ISO} .

cd -

umount ${MNTDIR}/ 

