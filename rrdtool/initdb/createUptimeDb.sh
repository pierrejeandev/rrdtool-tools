#!/bin/bash
##############################################################################
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
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#
# Copyrigth Pierre-Jean DEVILLE  2011-02-13
##############################################################################

# step: 5 minutes

time=$(date +%s)

rrdtool create dataUptime.rrd --step 300 --start $time \
  DS:uptime:GAUGE:3600:0:U DS:idletime:GAUGE:3600:0:U \
  RRA:AVERAGE:0.5:1:1500 RRA:AVERAGE:0.5:6:700 RRA:AVERAGE:0.5:24:700 RRA:AVERAGE:0.5:288:2300 \
      RRA:MAX:0.5:1:1500     RRA:MAX:0.5:6:700     RRA:MAX:0.5:24:700     RRA:MAX:0.5:288:2300 


