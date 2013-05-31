#
# Simple script to set up the environment

set -x
source ./env_vars.sh

mkdir -p { $MNTDIR $OPTDIR $CFGDIR $BLDDIR $ISODIR $IMGDIR }
cp ks.cfg $IMGDIR/

tree $VMHOME
