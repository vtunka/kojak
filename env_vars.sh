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
##############################################################################

# Distro information
VMNAME="Fedora-18-x86_64-DVD"
VMHOME="/mnt/media/USB0"
TMPDIR="/home/kojak"
DIST="RedHat/Fedora/18/0/x86_64"

# Sources and configuration
KSISO="Fedora-18-x86_64-DVD.iso"
KSCFG="Fedora-18-x86_64.cfg"

# Working directories
MNTDIR="${TMPDIR}/mnt/${DIST}"
CFGDIR="${TMPDIR}/cfg/${DIST}"
BLDDIR="${TMPDIR}/bld/${DIST}"
ISODIR="${TMPDIR}/iso/${DIST}"

# Virtual machine specifications
VMDISK="512000M"
VMMEM="4096"
