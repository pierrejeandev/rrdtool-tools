#!/bin/bash
##############################################################################
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, write to the Free Software
## Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
##
## Copyrigth Pierre-Jean DEVILLE  2011-02-13
###############################################################################

scriptFolder=$( dirname "${BASH_SOURCE[0]}" )
cd $scriptFolder

echo "## $(date) #############################" >>  ./rrd.log 2>&1
./cpu.rrd.pl         >> ./rrd.log 2>&1
./mem.rrd.pl         >> ./rrd.log 2>&1
./diskSpace.rrd.pl   >> ./rrd.log 2>&1
./diskIO.rrd.pl      >> ./rrd.log 2>&1
./uptime.rrd.pl      >> ./rrd.log 2>&1
./if.rrd.pl          >> ./rrd.log 2>&1
#./sensors.rrd.pl     >> ./rrd.log 2>&1

#./ping.rrd.pl Hisi ssl.hisi.fr &
#./ping.rrd.pl Piterpan www.piterpan.org &
#./ping.rrd.pl Google www.google.fr &
# /root/perl/rrd/ping.rrd.pl Google www.google.fr &


