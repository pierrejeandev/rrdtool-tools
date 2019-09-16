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


# OPTIONAL : save graphs to tmpsf to limit disk IO (useful on raspberrypi)
#if [ ! -d '/run/user/1000/rrd' ]; then
#  echo "Crating folder '/run/user/1000/rrd'"   >>  ./rrd.log 2>&1
#  mkdir -p '/run/user/1000/rrd';
#  # add read only access to lighttpd
#  setfacl -m u:www-data:rx /run/user/1000
#  # copy index html & css files
#  cp -p www/* /var/www/rrd/
#fi


#hourmin=$(date '+%H:%M')
#if [ "$hourmin" == "17:05" ]; then
#  echo "Copy www files to /var/www/rrd/"
#  cp -p www/* /var/www/rrd/
#fi


./cpu.rrd.pl         >> ./rrd.log 2>&1
./mem.rrd.pl         >> ./rrd.log 2>&1
./diskSpace.rrd.pl   >> ./rrd.log 2>&1
./diskIO.rrd.pl      >> ./rrd.log 2>&1
./uptime.rrd.pl      >> ./rrd.log 2>&1
./if.rrd.pl          >> ./rrd.log 2>&1

#./ping.rrd.pl Google www.google.fr &


